import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/theme.dart';
import '../../../app/widgets/stitch_widgets.dart';
import '../../prompt_editor/presentation/prompt_chat_panel.dart';
import '../../provider_config/presentation/providers/provider_config_provider.dart';
import 'provider/canvas_provider.dart';
import 'widgets/board_canvas.dart';
import 'widgets/chat_landing.dart';
import 'widgets/code_panel.dart';
import 'widgets/layers_panel.dart';
import 'widgets/prompt_bar.dart';

class CanvasPreviewPage extends StatelessWidget {
  const CanvasPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return const _DesktopShell();
        }
        return const _MobileShell();
      },
    );
  }
}

// ---------------------------------------------------------------- desktop --

class _DesktopShell extends ConsumerStatefulWidget {
  const _DesktopShell();

  @override
  ConsumerState<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<_DesktopShell> {
  bool _showPrompt = false;
  bool _showLayers = false;
  bool _showCode = false;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(canvasProvider.select((s) => s.outputMode));
    final hasUi = ref.watch(
      canvasProvider.select((s) => s.hasRenderedFrame || s.frames.isNotEmpty),
    );

    // Sinkronkan visibilitas panel dengan mode.
    // History (percakapan) selalu bisa dibuka, bahkan sebelum ada UI.
    final showCode = hasUi && (mode == OutputMode.dev || _showCode);
    final showLayers = hasUi && _showLayers;
    final showPrompt = _showPrompt;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          _TopBar(
            boardActive: hasUi,
            onTogglePrompt: () => setState(() => _showPrompt = !_showPrompt),
            onToggleLayers: () => setState(() => _showLayers = !_showLayers),
            onToggleCode: () => setState(() => _showCode = !_showCode),
            promptVisible: showPrompt,
            layersVisible: showLayers,
            codeVisible: showCode,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showPrompt) ...[
                    const SizedBox(
                      width: 300,
                      child: SoftPanel(
                        padding: EdgeInsets.zero,
                        clip: true,
                        child: PromptChatPanel(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Stack(
                      children: [
                        if (hasUi)
                          const BoardSurface()
                        else if (!showPrompt)
                          // Belum ada UI & panel riwayat tertutup: tampilkan
                          // percakapan besar di tengah (mode chatbot).
                          const ChatLanding()
                        else
                          // Panel riwayat terbuka: tengah cukup jadi latar netral.
                          const _EmptyCanvasHint(),
                        if (hasUi)
                          const Positioned(
                            right: 16,
                            top: 16,
                            bottom: 96,
                            child: _RightToolbar(),
                          ),
                        const Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: PromptBar(),
                        ),
                      ],
                    ),
                  ),
                  if (showLayers) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 280,
                      child: SoftPanel(
                        padding: EdgeInsets.zero,
                        clip: true,
                        child: _LayersPanel(),
                      ),
                    ),
                  ],
                  if (showCode) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 420,
                      child: SoftPanel(
                        padding: EdgeInsets.zero,
                        clip: true,
                        child: CodePanel(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.boardActive,
    required this.onTogglePrompt,
    required this.onToggleLayers,
    required this.onToggleCode,
    required this.promptVisible,
    required this.layersVisible,
    required this.codeVisible,
  });

  final bool boardActive;
  final VoidCallback onTogglePrompt;
  final VoidCallback onToggleLayers;
  final VoidCallback onToggleCode;
  final bool promptVisible;
  final bool layersVisible;
  final bool codeVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(providerConfigProvider).value?.activeProvider;

    return SizedBox(
      height: AppColors.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // History (percakapan) — selalu tersedia.
            SoftIconButton(
              icon: Icons.history,
              tooltip: 'Riwayat percakapan',
              active: promptVisible,
              onPressed: onTogglePrompt,
            ),
            const SizedBox(width: 4),
            // Konfigurasi provider — selalu tersedia.
            SoftIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Konfigurasi provider',
              onPressed: () => context.push('/provider-config'),
            ),
            const SizedBox(width: 12),
            // Toggle panel board (hanya relevan setelah ada UI).
            if (boardActive) ...[
              SoftIconButton(
                icon: Icons.layers_outlined,
                tooltip: 'Layers',
                active: layersVisible,
                onPressed: onToggleLayers,
              ),
              const SizedBox(width: 4),
              SoftIconButton(
                icon: Icons.code_outlined,
                tooltip: 'Code',
                active: codeVisible,
                onPressed: onToggleCode,
              ),
              const SizedBox(width: 12),
            ],
            InkWell(
              onTap: () => context.push('/provider-config'),
              borderRadius: AppRadius.pill,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active == null
                            ? AppColors.textDisabled
                            : AppColors.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(active?.name ?? 'Pilih provider', style: AppText.uiSmall),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (boardActive) const _CanvasViewControls(),
          ],
        ),
      ),
    );
  }
}

/// Kontrol kanan atas: zoom, grid, fit, bersihkan.
/// (Viewport dipilih lewat toggle di PromptBar.)
class _CanvasViewControls extends ConsumerWidget {
  const _CanvasViewControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasProvider);
    final notifier = ref.read(canvasProvider.notifier);

    return Row(
      children: [
        _ZoomChip(scale: state.scale),
        const SizedBox(width: 8),
        SoftIconButton(
          icon: Icons.grid_4x4,
          tooltip: 'Dot grid',
          active: state.showGrid,
          onPressed: notifier.toggleGrid,
        ),
        const SizedBox(width: 4),
        SoftIconButton(
          icon: Icons.fit_screen_outlined,
          tooltip: 'Fit ke frame',
          onPressed: state.frames.isEmpty
              ? null
              : () => notifier.centerOnFrames(boardViewportSize(context)),
        ),
        const SizedBox(width: 4),
        SoftIconButton(
          icon: Icons.delete_outline,
          tooltip: 'Bersihkan board',
          onPressed: state.frames.isEmpty ? null : notifier.clearBoard,
        ),
      ],
    );
  }
}

class _ZoomChip extends ConsumerWidget {
  const _ZoomChip({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(canvasProvider.notifier);
    final canZoomOut = scale > CanvasState.minScale + 0.0001;
    final canZoomIn = scale < CanvasState.maxScale - 0.0001;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            size: 28,
            iconSize: 15,
            onPressed: canZoomOut
                ? () => notifier.setScale(scale - 0.1)
                : null,
          ),
          InkWell(
            onTap: notifier.resetView,
            child: SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  '${(scale * 100).round()}%',
                  style: AppText.uiSmall,
                ),
              ),
            ),
          ),
          SoftIconButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            size: 28,
            iconSize: 15,
            onPressed: canZoomIn ? () => notifier.setScale(scale + 0.1) : null,
          ),
        ],
      ),
    );
  }
}

/// Toolbar vertikal kanan (select / pan / komentar / grid).
class _RightToolbar extends ConsumerWidget {
  const _RightToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(canvasProvider.select((s) => s.tool));
    final notifier = ref.read(canvasProvider.notifier);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.pill,
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppColors.shadowRaised,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolButton(
              icon: Icons.near_me_outlined,
              tooltip: 'Pilih & geser frame',
              active: tool == BoardTool.select,
              onTap: () => notifier.setTool(BoardTool.select),
            ),
            _ToolButton(
              icon: Icons.pan_tool_outlined,
              tooltip: 'Geser board',
              active: tool == BoardTool.hand,
              onTap: () => notifier.setTool(BoardTool.hand),
            ),
            _ToolButton(
              icon: Icons.zoom_out_map,
              tooltip: 'Fit ke frame',
              onTap: () =>
                  notifier.centerOnFrames(boardViewportSize(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.active
        ? AppColors.accentSoft
        : _hovered
        ? AppColors.hoverBg
        : Colors.transparent;
    final color = widget.active
        ? AppColors.accentPrimary
        : AppColors.textSecondary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(widget.icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _LayersPanel extends ConsumerWidget {
  const _LayersPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTree = ref.watch(
      canvasProvider.select((s) => s.activeFrame?.domTree != null),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PanelHeader(title: 'Layers'),
        Expanded(
          child: hasTree
              ? const LayersPanel()
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Pilih frame yang sudah dirender untuk melihat layers.',
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyCanvasHint extends StatelessWidget {
  const _EmptyCanvasHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dashboard_customize_outlined,
                size: 30,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada UI',
                style: const TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tulis prompt di bar bawah untuk mulai.',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Text(title, style: AppText.sectionTitle),
    );
  }
}

// ------------------------------------------------------------------ mobile --

class _MobileShell extends ConsumerWidget {
  const _MobileShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUi = ref.watch(
      canvasProvider.select((s) => s.hasRenderedFrame || s.frames.isNotEmpty),
    );

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(hasUi ? 'Board' : 'Centauri'),
        actions: [
          SoftIconButton(
            icon: Icons.history,
            tooltip: 'Riwayat percakapan',
            onPressed: () => _openSheet(
              context,
              const PromptChatPanel(),
              heightFactor: 0.7,
            ),
          ),
          SoftIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Konfigurasi provider',
            onPressed: () => context.push('/provider-config'),
          ),
          if (hasUi) ...[
            SoftIconButton(
              icon: Icons.layers_outlined,
              tooltip: 'Layers',
              onPressed: () => _openSheet(
                context,
                const _LayersPanel(),
                heightFactor: 0.6,
              ),
            ),
            SoftIconButton(
              icon: Icons.code_outlined,
              tooltip: 'Code',
              onPressed: () =>
                  _openSheet(context, const CodePanel(), heightFactor: 0.8),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Stack(
          children: [
            if (hasUi) const BoardSurface() else const ChatLanding(),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PromptBar(),
            ),
          ],
        ),
      ),
    );
  }

  static void _openSheet(
    BuildContext context,
    Widget child, {
    required double heightFactor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * heightFactor,
        child: child,
      ),
    );
  }
}

/// Ukuran viewport board saat ini (untuk perhitungan fit/center).
Size boardViewportSize(BuildContext context) {
  final box = BoardSurface.boardViewportKey.currentContext?.findRenderObject()
      as RenderBox?;
  if (box != null && box.hasSize) return box.size;
  return const Size(900, 600);
}
