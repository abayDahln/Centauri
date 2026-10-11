import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/theme.dart';
import '../../prompt_editor/presentation/prompt_chat_panel.dart';
import '../../provider_config/presentation/widgets/provider_status_card.dart';
import '../data/services/canvas_webview_service.dart';
import '../data/services/canvas_webview_service_factory.dart';
import '../domain/viewport_mode.dart';
import 'provider/canvas_provider.dart';

class CanvasPreviewPage extends StatelessWidget {
  const CanvasPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return const _DesktopCanvasLayout();
        }
        return const _MobileCanvasLayout();
      },
    );
  }
}

class _DesktopCanvasLayout extends StatelessWidget {
  const _DesktopCanvasLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.bgBase,
                border: Border(
                  right: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: const _SidebarContent(),
            ),
          ),
          const Expanded(child: _CanvasWorkspace()),
          SizedBox(
            width: 380,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.bgBase,
                border: Border(
                  left: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: const PromptChatPanel(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Centauri',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'AI UI/UX Canvas',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textDisabled,
            ),
          ),
        ),
        const Divider(height: 1),
        const ProviderStatusCard(),
      ],
    );
  }
}

class _CanvasWorkspace extends ConsumerWidget {
  const _CanvasWorkspace();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const _ViewportToolbar(),
        const Divider(height: 1),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _CanvasPanel(),
          ),
        ),
      ],
    );
  }
}

class _ViewportToolbar extends ConsumerWidget {
  const _ViewportToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(canvasProvider.select((s) => s.viewport));

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Text(
            'Live Canvas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 30,
            child: SegmentedButton<ViewportMode>(
              segments: ViewportMode.values
                  .map((mode) => ButtonSegment<ViewportMode>(
                        value: mode,
                        tooltip: mode.label,
                        label: Text(
                          mode.widthLabel,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                          ),
                        ),
                      ))
                  .toList(),
              selected: {viewport},
              onSelectionChanged: (selection) =>
                  ref.read(canvasProvider.notifier).setViewport(selection.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                side: WidgetStateProperty.all(
                  const BorderSide(color: AppColors.borderSubtle),
                ),
                backgroundColor:
                    WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.accentPrimary;
                  }
                  return AppColors.bgSurface;
                }),
                foregroundColor:
                    WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppColors.textSecondary;
                }),
              ),
            ),
          ),
          const Spacer(),
          Text(
            viewport.label,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _CanvasPanel extends ConsumerWidget {
  const _CanvasPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasContent =
        ref.watch(canvasProvider.select((s) => s.generatedHtml != null));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            const CanvasWebviewHost(),
            if (!hasContent) const _CanvasPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _CanvasPlaceholder extends StatelessWidget {
  const _CanvasPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.web_asset_outlined, size: 40, color: AppColors.textDisabled),
          SizedBox(height: 12),
          Text(
            'Canvas siap',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tulis prompt di panel kanan untuk mulai generate UI',
            style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

/// Host WebView: mengelola lifecycle service per-platform dan mendorong
/// perubahan state (HTML + viewport) ke dalam canvas.
class CanvasWebviewHost extends ConsumerStatefulWidget {
  const CanvasWebviewHost({super.key});

  @override
  ConsumerState<CanvasWebviewHost> createState() => _CanvasWebviewHostState();
}

class _CanvasWebviewHostState extends ConsumerState<CanvasWebviewHost> {
  final CanvasWebviewService _service = createCanvasWebviewService();
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
      await _service.renderHtml(state.generatedHtml);
      await _service.setViewportWidth(state.viewport.width);
    } catch (_) {
      // WebView gagal init (mis. WebView2 runtime tidak tersedia).
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(canvasProvider.select((s) => s.generatedHtml),
        (_, html) => _service.renderHtml(html));
    ref.listen<ViewportMode>(canvasProvider.select((s) => s.viewport),
        (_, mode) => _service.setViewportWidth(mode.width));

    if (!_ready) {
      return const Center(
        child: SizedBox(
          height: 20,
          width: 20,
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

class _MobileCanvasLayout extends StatelessWidget {
  const _MobileCanvasLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centauri Canvas'),
        actions: [
          IconButton(
            tooltip: 'Provider settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/provider-config'),
          ),
        ],
      ),
      body: const Column(
        children: [
          _ViewportToolbar(),
          Divider(height: 1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: _CanvasPanel(),
            ),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton.extended(
          backgroundColor: AppColors.accentPrimary,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.bgBase,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              side: BorderSide(color: AppColors.borderSubtle),
            ),
            builder: (_) => const SizedBox(
              height: 640,
              child: PromptChatPanel(),
            ),
          ),
          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          label: const Text(
            'Chat',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
