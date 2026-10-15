import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../data/services/canvas_service_registry.dart';
import '../../data/services/canvas_webview_service.dart';
import '../../data/services/canvas_webview_service_factory.dart';
import '../../domain/board_frame.dart';
import '../provider/canvas_provider.dart';

/// Satu frame di board: kartu mengambang berisi WebView yang merender HTML
/// frame tersebut. Setiap frame punya service WebView sendiri.
///
/// **Skala tunggal (anti zoom-ganda).** WebView SELALU dirender pada skala
/// 1.0 (viewport CSS = lebar desain asli, mis. 390px) sehingga konten tidak
/// pernah "pecah". Seluruh kartu kemudian di-`Transform.scale(scale)` oleh
/// Flutter dari sudut kiri-atas, dan diposisikan di `pan + offset*scale`.
/// Dengan satu sumber skala saja, border/radius/label ikut membesar-mengecil
/// seragam dan ukuran frame selalu konsisten dengan skala board.
class BoardFrameView extends ConsumerStatefulWidget {
  const BoardFrameView({
    super.key,
    required this.frame,
    required this.scale,
    required this.pan,
  });

  final BoardFrame frame;

  /// Skala board saat ini.
  final double scale;

  /// Pergeseran board saat ini.
  final Offset pan;

  @override
  ConsumerState<BoardFrameView> createState() => _BoardFrameViewState();
}

class _BoardFrameViewState extends ConsumerState<BoardFrameView> {
  final CanvasWebviewService _service = createCanvasWebviewService();
  StreamSubscription<CanvasSelectEvent>? _subscription;
  bool _ready = false;

  /// Gagal init/render WebView. Null = sehat. Ditampilkan sebagai placeholder
  /// error (bukan kartu putih kosong) agar kegagalan WebView2 terlihat.
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    CanvasServiceRegistry.register(widget.frame.id, _service);
    try {
      await _service.init();
      // Dengarkan event SEBELUM render agar laporan `resize` pertama dari
      // shell (yang menentukan tinggi frame) tidak hilang — broadcast
      // stream membuang event saat belum ada listener.
      _subscription = _service.selectionEvents.listen(
        _onEvent,
        onError: (Object e) => debugPrint('[canvas] bridge error: $e'),
      );
      // Konten dirender pada lebar CSS asli frame (mis. 390px) dengan skala
      // WebView = 1.0. Skala board ditangani oleh Transform Flutter, bukan
      // zoomFactor, sehingga tidak ada zoom ganda (penyebab UI "pecah").
      await _service.setViewportWidth(widget.frame.size.width);
      await _service.setZoom(1.0);
      await _service.renderHtml(
        widget.frame.html.isEmpty ? null : widget.frame.html,
      );
    } catch (e) {
      // Mis. runtime WebView2 tidak tersedia/rusak. Jangan telan diam-diam:
      // tampilkan pesannya agar user tahu cara memperbaiki (install runtime,
      // update Edge WebView2, dsb.) ketimbang menatap frame putih kosong.
      debugPrint('[canvas] WebView gagal init/render: $e');
      _error = '$e';
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _retryRender() async {
    if (mounted) setState(() => _error = null);
    try {
      await _service.setViewportWidth(widget.frame.size.width);
      await _service.setZoom(1.0);
      await _service.renderHtml(
        widget.frame.html.isEmpty ? null : widget.frame.html,
      );
    } catch (e) {
      debugPrint('[canvas] retry render gagal: $e');
      if (mounted) setState(() => _error = '$e');
    }
  }

  void _onEvent(CanvasSelectEvent event) {
    // Event ekspor/sinkronisasi dikonsumsi peminta via stream yang sama;
    // bukan interaksi seleksi — abaikan di sini.
    if (event.type == 'png' ||
        event.type == 'pngError' ||
        event.type == 'html' ||
        event.type == 'outerHtml' ||
        event.type == 'outerHtmlError') {
      return;
    }

    // Kegagalan render/bridge dari JS atau WebView: tampilkan sebagai pesan
    // agar frame tidak tampil putih kosong tanpa penjelasan (hardening).
    if (event.type == 'error') {
      final message = event.errorMessage ?? 'Terjadi kesalahan di canvas.';
      debugPrint('[canvas] bridge error: $message');
      if (mounted) setState(() => _error = message);
      return;
    }

    // Dokumen selesai dirender: bersihkan error lama bila ada.
    if (event.type == 'ready') {
      if (mounted && _error != null) setState(() => _error = null);
      return;
    }

    final notifier = ref.read(canvasProvider.notifier);
    if (event.type == 'resize') {
      // Tinggi frame WAJIB mengikuti isi. Karena layout selalu logis (constraint
      // dilepas), `contentHeight` tidak berubah akibat zoom — jadi tidak perlu
      // menahan laporan resize. Menahannya justru membuat frame tertinggal
      // pendek bila laporan sesungguhnya tiba tepat setelah zoom.
      final height = event.contentHeight;
      if (height != null && height > 0) {
        notifier.setFrameContentHeight(widget.frame.id, height);
      }
      return;
    }
    if (event.type == 'geometry') {
      // Hanya terima geometri untuk frame aktif agar race antar frame aman.
      final activeId = ref.read(canvasProvider).activeFrameId;
      if (widget.frame.id != activeId) return;
      final geometry = event.geometry;
      if (geometry != null) notifier.updateNodeGeometry(geometry);
      return;
    }

    // Interaksi dari canvas: aktifkan frame ini lebih dulu, baru teruskan.
    final activeId = ref.read(canvasProvider).activeFrameId;
    if (widget.frame.id != activeId) {
      notifier.selectFrame(widget.frame.id);
    }

    if (event.type == 'select') {
      notifier.selectNodeFromCanvas(event.id);
    } else if (event.type == 'hover') {
      notifier.hoverNode(event.id);
    }
  }

  @override
  void didUpdateWidget(covariant BoardFrameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.html != widget.frame.html) {
      // Future tidak bisa di-await di sini; tangkap error-nya agar tidak
      // jadi unhandled async error dan agar kegagalan render terlihat.
      _service
          .renderHtml(widget.frame.html.isEmpty ? null : widget.frame.html)
          .then((_) {
            if (mounted && _error != null) setState(() => _error = null);
          })
          .catchError((Object e) {
            debugPrint('[canvas] renderHtml gagal: $e');
            if (mounted) setState(() => _error = '$e');
          });
    }
    if (oldWidget.frame.size.width != widget.frame.size.width) {
      _service.setViewportWidth(widget.frame.size.width).catchError((Object e) {
        debugPrint('[canvas] setViewportWidth gagal: $e');
      });
    }
    // Skala board ditangani Transform Flutter (bukan WebView), jadi tidak ada
    // re-setZoom saat `scale` berubah. WebView SELALU 1.0: jangan pernah
    // teruskan `widget.scale` ke setZoom — itu penyebab double-zoom.
  }

  @override
  void dispose() {
    CanvasServiceRegistry.unregister(widget.frame.id);
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = ref.watch(
      canvasProvider.select((s) => s.activeFrameId == widget.frame.id),
    );

    ref.listen<String?>(
      canvasProvider.select((s) => s.selectedNodeId),
      (_, id) => _service.selectNode(isActive ? id : null),
    );
    ref.listen<String?>(
      canvasProvider.select((s) => s.hoveredNodeId),
      (_, id) => _service.hoverNode(isActive ? id : null),
    );

    return _FrameCard(
      frame: widget.frame,
      isActive: isActive,
      scale: widget.scale,
      pan: widget.pan,
      // Saat tool hand (Space/pan) aktif, boardlah yang menangani drag —
      // frame tidak boleh ikut bergerak agar tidak dobel dengan pan board.
      boardPanning: ref.watch(
        canvasProvider.select((s) => s.tool == BoardTool.hand),
      ),
      onSelect: () =>
          ref.read(canvasProvider.notifier).selectFrame(widget.frame.id),
      onDelete: () =>
          ref.read(canvasProvider.notifier).deleteFrame(widget.frame.id),
      onDrag: (delta) =>
          ref.read(canvasProvider.notifier).moveFrame(widget.frame.id, delta),
      onDragEnd: () => ref.read(canvasProvider.notifier).endFrameDrag(),
      onClearSelection: () =>
          ref.read(canvasProvider.notifier).selectNode(null),
      onResizeWidth: (newWidth) =>
          ref.read(canvasProvider.notifier).setFrameWidth(widget.frame.id, newWidth),
      child: !_ready
          ? const _WebviewLoading()
          : (_error != null
                ? _WebviewError(message: _error!, onRetry: _retryRender)
                : _service.buildView()),
    );
  }
}

class _WebviewError extends StatelessWidget {
  const _WebviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgSunken,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.web_asset_off_outlined,
                size: 26,
                color: AppColors.statusError,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pratinjau gagal dimuat',
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.length > 220
                    ? '${message.substring(0, 220)}…'
                    : message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 10.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bila tetap gagal: pastikan Microsoft Edge WebView2 Runtime terinstal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppColors.textDisabled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebviewLoading extends StatelessWidget {
  const _WebviewLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.bgSurface,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentPrimary,
          ),
        ),
      ),
    );
  }
}

/// Kartu frame: judul + area konten + ring aksen saat aktif.
///
/// Kartu digambar pada **ukuran logis** frame (mis. 390×844), lalu seluruh
/// kartu di-`Transform.scale(scale)` dari sudut kiri-atas dan diposisikan di
/// `pan + offset*scale`. WebView di dalamnya selalu skala 1.0 → konten tidak
/// pecah dan border/radius/label membesar-mengecil seragam.
class _FrameCard extends StatelessWidget {
  const _FrameCard({
    required this.frame,
    required this.isActive,
    required this.scale,
    required this.pan,
    required this.onSelect,
    required this.onDelete,
    required this.onDrag,
    required this.child,
    this.boardPanning = false,
    this.onClearSelection,
    this.onDragEnd,
    this.onResizeWidth,
  });

  final BoardFrame frame;
  final bool isActive;
  final double scale;
  final Offset pan;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onDrag;
  final Widget child;

  /// True bila board sedang dalam mode pan (tool hand / Space). Saat true,
  /// drag di atas frame diteruskan ke board, bukan memindahkan frame.
  final bool boardPanning;

  final VoidCallback? onClearSelection;
  final VoidCallback? onDragEnd;
  final ValueChanged<double>? onResizeWidth;

  @override
  Widget build(BuildContext context) {
    // Posisi di ruang layar (sudut kiri-atas kartu setelah di-scale).
    final screenLeft = pan.dx + frame.offset.dx * scale;
    final screenTop = pan.dy + frame.offset.dy * scale;

    // PENTING: layout vs paint dipisah.
    // - `Positioned` TANPA width/height: Stack memberi constraint LONGGAR,
    //   sehingga child menentukan ukurannya sendiri (ukuran LOGIS, mis. 390px)
    //   apa pun skala board.
    // - `Transform.scale` meng-scale paint dari kiri-atas (visual ala Figma/Stitch);
    //   hit-test tetap benar karena Transform meng-inverse transform saat
    //   hit-testing, jadi drag/tap tetap akurat di area visual kartu.
    final borderWidth = isActive ? 1.5 : 1.0;
    final innerRadius = BorderRadius.all(Radius.circular(12.0 - borderWidth));

    return Positioned(
      left: screenLeft,
      top: screenTop,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        filterQuality: FilterQuality.high,
        child: SizedBox(
          width: frame.size.width,
          height: frame.size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Label frame (ikut skala bersama kartu).
                  SizedBox(
                    height: 22,
                    child: _FrameLabel(
                      frame: frame,
                      isActive: isActive,
                      onSelect: onSelect,
                      onDelete: onDelete,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: MouseRegion(
                      cursor: boardPanning
                          ? SystemMouseCursors.grab
                          : SystemMouseCursors.move,
                      child: GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTap: onSelect,
                        onPanUpdate: boardPanning
                            ? null
                            : (details) => onDrag(details.delta),
                        onPanEnd: boardPanning ? null : (_) => onDragEnd?.call(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: AppRadius.md,
                            border: Border.all(
                              color: isActive
                                  ? AppColors.accentPrimary
                                  : AppColors.borderSubtle,
                              width: borderWidth,
                            ),
                            boxShadow: AppColors.shadowRaised,
                          ),
                          child: ClipRRect(
                            borderRadius: innerRadius,
                            clipBehavior: Clip.antiAlias,
                            child: ColoredBox(
                              color: AppColors.bgSurface,
                              child: RepaintBoundary(child: child),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Dynamic resize handle di sisi kanan frame ala Google Stitch
              if (isActive && !boardPanning)
                Positioned(
                  top: 28,
                  bottom: 0,
                  right: -7,
                  width: 14,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) {
                        final newWidth = (frame.size.width + details.delta.dx)
                            .clamp(280.0, 3840.0);
                        onResizeWidth?.call(newWidth);
                      },
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPrimary.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrameLabel extends StatelessWidget {
  const _FrameLabel({
    required this.frame,
    required this.isActive,
    required this.onSelect,
    required this.onDelete,
  });

  final BoardFrame frame;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.crop_square,
          size: 13,
          color: isActive ? AppColors.accentPrimary : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            frame.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.uiFamily,
              fontFamilyFallback: AppFonts.uiFallback,
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? AppColors.accentPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Badge info ukuran frame — otomatis dari AI, bukan pilihan manual.
        _FrameDimensionBadge(frame: frame, isActive: isActive),
        if (isActive) ...[
          const SizedBox(width: 4),
          _FrameAction(
            icon: Icons.close,
            tooltip: 'Hapus frame',
            onTap: onDelete,
          ),
        ],
      ],
    );
  }
}

/// Badge info ukuran frame (read-only).
/// Ukuran awal sepenuhnya otomatis dari AI berdasarkan prompt user —
/// tidak ada preset mobile/tablet/desktop manual di sini.
class _FrameDimensionBadge extends StatelessWidget {
  const _FrameDimensionBadge({required this.frame, required this.isActive});

  final BoardFrame frame;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final w = frame.size.width.round();
    final h = frame.size.height.round();
    return Tooltip(
      message: 'Ukuran otomatis dari AI (ubah via prompt, mis. "buat versi mobile")',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentPrimary.withValues(alpha: 0.1)
              : AppColors.bgSunken,
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: isActive
                ? AppColors.accentPrimary.withValues(alpha: 0.3)
                : AppColors.borderSubtle,
            width: 0.8,
          ),
        ),
        child: Text(
          '$w × $h',
          style: TextStyle(
            fontFamily: AppFonts.monoFamily,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColors.accentPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FrameAction extends StatelessWidget {
  const _FrameAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sm,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, size: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
