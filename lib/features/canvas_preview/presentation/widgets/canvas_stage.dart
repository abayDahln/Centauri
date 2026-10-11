import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../data/services/canvas_webview_service.dart';
import '../../data/services/canvas_webview_service_factory.dart';
import '../../domain/viewport_mode.dart';
import '../provider/canvas_provider.dart';

/// Stage canvas: membungkus WebView native, mendorong perubahan state
/// (HTML, viewport, zoom, seleksi) ke dalam shell, dan menerima event
/// seleksi/hover dari canvas untuk disinkronkan ke layers tree.
class CanvasStage extends ConsumerWidget {
  const CanvasStage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasContent = ref.watch(
      canvasProvider.select((s) => s.generatedHtml != null),
    );

    return Container(
      color: AppColors.bgBase,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgBase,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              const CanvasWebviewHost(),
              if (!hasContent) const CanvasPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }
}

class CanvasPlaceholder extends StatelessWidget {
  const CanvasPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.bgBase,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.brush_outlined, size: 28, color: AppColors.textDisabled),
            SizedBox(height: 12),
            Text('Canvas kosong', style: AppText.ui),
            SizedBox(height: 6),
            Text(
              'Buka panel Prompt, lalu ketik deskripsi UI untuk mulai.',
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// Host WebView: mengelola lifecycle service per-platform dan mendorong
/// perubahan state ke dalam canvas. Juga meneruskan event seleksi dari
/// canvas kembali ke [canvasProvider].
class CanvasWebviewHost extends ConsumerStatefulWidget {
  const CanvasWebviewHost({super.key});

  @override
  ConsumerState<CanvasWebviewHost> createState() => _CanvasWebviewHostState();
}

class _CanvasWebviewHostState extends ConsumerState<CanvasWebviewHost> {
  final CanvasWebviewService _service = createCanvasWebviewService();
  StreamSubscription<CanvasSelectEvent>? _selectionSubscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final state = ref.read(canvasProvider);
    try {
      await _service.init();
      await _service.setViewportWidth(state.viewport.width);
      await _service.setZoom(state.zoom);
      await _service.renderHtml(state.generatedHtml);

      _selectionSubscription = _service.selectionEvents.listen(_onCanvasEvent);
    } catch (_) {
      // WebView gagal init (mis. WebView2 runtime tidak tersedia).
    }
    if (mounted) setState(() => _ready = true);
  }

  void _onCanvasEvent(CanvasSelectEvent event) {
    final notifier = ref.read(canvasProvider.notifier);
    if (event.type == 'select') {
      notifier.selectNodeFromCanvas(event.id);
    } else if (event.type == 'hover') {
      notifier.hoverNode(event.id);
    }
  }

  @override
  void dispose() {
    _selectionSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      canvasProvider.select((s) => s.generatedHtml),
      (_, html) => _service.renderHtml(html),
    );
    ref.listen<ViewportMode>(
      canvasProvider.select((s) => s.viewport),
      (_, mode) => _service.setViewportWidth(mode.width),
    );
    ref.listen<double>(
      canvasProvider.select((s) => s.zoom),
      (_, zoom) => _service.setZoom(zoom),
    );
    ref.listen<String?>(
      canvasProvider.select((s) => s.selectedNodeId),
      (_, id) => _service.selectNode(id),
    );
    ref.listen<String?>(
      canvasProvider.select((s) => s.hoveredNodeId),
      (_, id) => _service.hoverNode(id),
    );

    if (!_ready) {
      return const Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentPrimary,
          ),
        ),
      );
    }

    return _service.buildView();
  }
}
