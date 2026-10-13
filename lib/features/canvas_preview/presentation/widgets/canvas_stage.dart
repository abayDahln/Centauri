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
/// Frame diposisikan dan diukur di **ruang layar** (memakai `pan` + `scale`),
/// bukan lewat Transform. Dengan begitu WebView dirender pada ukuran piksel
/// akhirnya sehingga tetap tajam di semua tingkat zoom.
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
      // Konten dirender pada ukuran CSS asli frame (lebar tetap), lalu
      // WebView di-zoom agar ukuran piksel mengikuti skala board -> tajam.
      await _service.setViewportWidth(widget.frame.size.width);
      await _service.setZoom(widget.scale);
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
      await _service.setZoom(widget.scale);
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
          .renderHtml(
            widget.frame.html.isEmpty ? null : widget.frame.html,
          )
          .then((_) {
            if (mounted && _error != null) setState(() => _error = null);
          })
          .catchError((Object e) {
            debugPrint('[canvas] renderHtml gagal: $e');
            if (mounted) setState(() => _error = '$e');
          });
    }
    if (oldWidget.frame.size.width != widget.frame.size.width) {
      _service.setViewportWidth(widget.frame.size.width).catchError((
        Object e,
      ) {
        debugPrint('[canvas] setViewportWidth gagal: $e');
      });
    }
    if (oldWidget.scale != widget.scale) {
      _service.setZoom(widget.scale).catchError((Object e) {
        debugPrint('[canvas] setZoom gagal: $e');
      });
    }
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
      boardPanning:
          ref.watch(canvasProvider.select((s) => s.tool == BoardTool.hand)),
      onSelect: () =>
          ref.read(canvasProvider.notifier).selectFrame(widget.frame.id),
      onDelete: () =>
          ref.read(canvasProvider.notifier).deleteFrame(widget.frame.id),
      onDrag: (delta) =>
          ref.read(canvasProvider.notifier).moveFrame(widget.frame.id, delta),
      onDragEnd: () => ref.read(canvasProvider.notifier).endFrameDrag(),
      onClearSelection: () =>
          ref.read(canvasProvider.notifier).selectNode(null),
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
                message.length > 220 ? '${message.substring(0, 220)}…' : message,
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
/// Ukuran & posisi dihitung di ruang layar: `pan + offset*scale`, dengan
/// lebar/tinggi `size*scale`. WebView di dalamnya di-zoom via `setZoomFactor`
/// sehingga tajam.
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

  @override
  Widget build(BuildContext context) {
    final screenLeft = pan.dx + frame.offset.dx * scale;
    final screenTop = pan.dy + frame.offset.dy * scale;
    final screenWidth = frame.size.width * scale;
    final screenHeight = frame.size.height * scale;

    // Skala label agar tetap terbaca (tidak ikut mengecil ekstrem).
    final labelScale = scale.clamp(0.5, 1.0);

    return Positioned(
      left: screenLeft,
      top: screenTop,
      width: screenWidth,
      height: screenHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20 * labelScale,
            child: Transform.scale(
              scale: labelScale,
              alignment: Alignment.centerLeft,
              child: _FrameLabel(
                frame: frame,
                isActive: isActive,
                onSelect: onSelect,
                onDelete: onDelete,
              ),
            ),
          ),
          SizedBox(height: 6 * labelScale),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: onSelect,
              // Delta drag dari gesture sudah dalam piksel layar; konversi ke
              // koordinat board dengan membagi scale.
              // Saat board panning (hand tool), drag TIDAK memindah frame:
              // gesture dibiarkan lolos ke Listener board.
              onPanUpdate: boardPanning
                  ? null
                  : (details) => onDrag(details.delta / scale),
              onPanEnd: boardPanning ? null : (_) => onDragEnd?.call(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: AppRadius.md,
                  border: Border.all(
                    color: isActive
                        ? AppColors.accentPrimary
                        : AppColors.borderSubtle,
                    width: isActive ? 1.8 : 1,
                  ),
                  boxShadow: AppColors.shadowRaised,
                ),
                clipBehavior: Clip.antiAlias,
                // WebView (Texture) menangani klik elemen sendiri: klik node
                // mengirim event `select` lewat bridge JS→Dart. Tidak ada
                // overlay Flutter di atasnya agar klik tidak tertelan.
                child: child,
              ),
            ),
          ),
        ],
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
        if (isActive)
          _FrameAction(
            icon: Icons.close,
            tooltip: 'Hapus frame',
            onTap: onDelete,
          ),
      ],
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
