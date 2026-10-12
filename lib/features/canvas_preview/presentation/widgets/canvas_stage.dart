import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../data/services/canvas_webview_service.dart';
import '../../data/services/canvas_webview_service_factory.dart';
import '../../domain/board_frame.dart';
import '../provider/canvas_provider.dart';

/// Satu frame di board: kartu mengambang berisi WebView yang merender HTML
/// frame tersebut. Setiap frame punya service WebView sendiri.
class BoardFrameView extends ConsumerStatefulWidget {
  const BoardFrameView({
    super.key,
    required this.frame,
    required this.scale,
  });

  final BoardFrame frame;

  /// Skala board saat ini (dipakai untuk drag frame yang akurat).
  final double scale;

  @override
  ConsumerState<BoardFrameView> createState() => _BoardFrameViewState();
}

class _BoardFrameViewState extends ConsumerState<BoardFrameView> {
  final CanvasWebviewService _service = createCanvasWebviewService();
  StreamSubscription<CanvasSelectEvent>? _subscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.init();
      // Konten dirender tepat selebar frame dan tanpa zoom internal.
      // Skala visual ditangani oleh Transform board, bukan oleh WebView.
      await _service.setViewportWidth(widget.frame.size.width);
      await _service.setZoom(1);
      await _service.renderHtml(
        widget.frame.html.isEmpty ? null : widget.frame.html,
      );
      _subscription = _service.selectionEvents.listen(_onEvent);
    } catch (_) {
      // WebView gagal init (mis. runtime WebView2 tidak tersedia).
    }
    if (mounted) setState(() => _ready = true);
  }

  void _onEvent(CanvasSelectEvent event) {
    final notifier = ref.read(canvasProvider.notifier);
    if (event.type == 'resize') {
      final height = event.contentHeight;
      if (height != null && height > 0) {
        notifier.setFrameContentHeight(widget.frame.id, height);
      }
      return;
    }
    if (widget.frame.id != ref.read(canvasProvider).activeFrameId) return;
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
      _service.renderHtml(
        widget.frame.html.isEmpty ? null : widget.frame.html,
      );
    }
    if (oldWidget.frame.size.width != widget.frame.size.width) {
      _service.setViewportWidth(widget.frame.size.width);
    }
  }

  @override
  void dispose() {
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
      onSelect: () =>
          ref.read(canvasProvider.notifier).selectFrame(widget.frame.id),
      onDelete: () =>
          ref.read(canvasProvider.notifier).deleteFrame(widget.frame.id),
      onDrag: (delta) =>
          ref.read(canvasProvider.notifier).moveFrame(widget.frame.id, delta),
      child: _ready
          ? _service.buildView()
          : const _WebviewLoading(),
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
class _FrameCard extends StatelessWidget {
  const _FrameCard({
    required this.frame,
    required this.isActive,
    required this.scale,
    required this.onSelect,
    required this.onDelete,
    required this.onDrag,
    required this.child,
  });

  final BoardFrame frame;
  final bool isActive;
  final double scale;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onDrag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: frame.offset.dx,
      top: frame.offset.dy,
      width: frame.size.width,
      height: frame.size.height,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: onSelect,
        onPanUpdate: (details) => onDrag(details.delta / scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FrameLabel(
              frame: frame,
              isActive: isActive,
              onSelect: onSelect,
              onDelete: onDelete,
            ),
            const SizedBox(height: 6),
            Expanded(
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
                child: child,
              ),
            ),
          ],
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
