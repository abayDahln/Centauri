import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/theme.dart';
import '../../prompt_editor/domain/prompt_templates.dart';
import '../../prompt_editor/presentation/prompt_chat_panel.dart';
import '../../provider_config/presentation/providers/provider_config_provider.dart';
import '../../provider_config/presentation/widgets/provider_status_card.dart';
import '../domain/viewport_mode.dart';
import 'provider/canvas_provider.dart';
import 'widgets/canvas_stage.dart';
import 'widgets/code_panel.dart';
import 'widgets/layers_panel.dart';

enum _Activity { explorer, chat }

class CanvasPreviewPage extends StatelessWidget {
  const CanvasPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return const _DesktopShell();
        }
        return const _MobileShell();
      },
    );
  }
}

// ---------------------------------------------------------------- desktop --

class _DesktopShell extends StatefulWidget {
  const _DesktopShell();

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  _Activity _activity = _Activity.explorer;
  bool _sideBarVisible = true;

  void _selectActivity(_Activity activity) {
    setState(() {
      if (_activity == activity) {
        _sideBarVisible = !_sideBarVisible;
      } else {
        _activity = activity;
        _sideBarVisible = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _ActivityBar(activity: _activity, onSelected: _selectActivity),
          if (_sideBarVisible) ...[
            _SideBarPanel(activity: _activity),
            const VerticalDivider(width: 1),
          ],
          const Expanded(child: _EditorArea()),
        ],
      ),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({required this.activity, required this.onSelected});

  final _Activity activity;
  final ValueChanged<_Activity> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppColors.activityBarWidth,
      color: AppColors.chromeBg,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          const SizedBox(
            height: 44,
            child: Center(
              child: Text(
                'C',
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
          ),
          _ActivityButton(
            icon: Icons.layers_outlined,
            tooltip: 'Explorer: provider, layers, tokens',
            selected: activity == _Activity.explorer,
            onPressed: () => onSelected(_Activity.explorer),
          ),
          _ActivityButton(
            icon: Icons.forum_outlined,
            tooltip: 'Prompt & iterasi',
            selected: activity == _Activity.chat,
            onPressed: () => onSelected(_Activity.chat),
          ),
          const Spacer(),
          _ActivityButton(
            icon: Icons.settings_outlined,
            tooltip: 'Provider settings',
            selected: false,
            onPressed: () => context.push('/provider-config'),
          ),
        ],
      ),
    );
  }
}

class _ActivityButton extends StatelessWidget {
  const _ActivityButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppColors.activityBarWidth,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: selected ? AppColors.accentPrimary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
        iconSize: 22,
        splashRadius: 22,
        icon: Icon(
          icon,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return AppColors.hoverBg;
            return Colors.transparent;
          }),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _SideBarPanel extends StatelessWidget {
  const _SideBarPanel({required this.activity});

  final _Activity activity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppColors.sideBarWidth,
      child: ColoredBox(
        color: AppColors.chromeBg,
        child: switch (activity) {
          _Activity.explorer => const _ExplorerView(),
          _Activity.chat => const _ChatView(),
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- sidebar --

class _ExplorerView extends ConsumerWidget {
  const _ExplorerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _SideBarSection(
          title: 'Provider',
          actions: [
            _SideBarIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Kelola provider',
              onPressed: () => context.push('/provider-config'),
            ),
          ],
          child: const ProviderStatusCard(),
        ),
        const Divider(height: 1),
        const _LayersSection(),
        const Divider(height: 1),
        const _DesignTokensSection(),
        const Divider(height: 1),
        const _AboutSection(),
      ],
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SideBarSection(title: 'Prompt & Iterasi', child: SizedBox.shrink()),
        Divider(height: 1),
        Expanded(child: PromptChatPanel()),
      ],
    );
  }
}

class _LayersSection extends ConsumerWidget {
  const _LayersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTree = ref.watch(
      canvasProvider.select((s) => s.domTree != null),
    );
    final selectedLabel = ref.watch(
      canvasProvider.select((s) {
        final id = s.selectedNodeId;
        if (id == null) return null;
        return s.domTree?.findById(id)?.label;
      }),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 22,
          padding: const EdgeInsets.only(left: 12, right: 4),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              const Expanded(
                child: Text('LAYERS', style: AppText.sectionHeader),
              ),
              if (selectedLabel != null)
                Flexible(
                  child: Text(
                    selectedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ),
              _SideBarIconButton(
                icon: Icons.clear_all,
                tooltip: 'Lepas pilihan',
                onPressed: () =>
                    ref.read(canvasProvider.notifier).selectNode(null),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: hasTree
              ? const LayersPanel()
              : const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    'Belum ada layer. Generate UI untuk melihat struktur elemen.',
                    style: AppText.caption,
                  ),
                ),
        ),
      ],
    );
  }
}

class _SideBarSection extends StatelessWidget {
  const _SideBarSection({
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 22,
          padding: const EdgeInsets.only(left: 12, right: 4),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppText.sectionHeader,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...actions,
            ],
          ),
        ),
        child,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SideBarIconButton extends StatelessWidget {
  const _SideBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: IconButton(
        icon: Icon(icon, size: 14),
        tooltip: tooltip,
        splashRadius: 12,
        padding: EdgeInsets.zero,
        color: AppColors.textSecondary,
        onPressed: onPressed,
      ),
    );
  }
}

class _DesignTokensSection extends ConsumerWidget {
  const _DesignTokensSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(
      canvasProvider.select((s) => s.selectedToken?.id),
    );

    return _SideBarSection(
      title: 'Design Tokens',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _swatches.entries.map((entry) {
            final preset = entry.key;
            final selected = preset.id == selectedId;
            return _TokenChip(
              label: preset.label,
              swatch: entry.value,
              selected: selected,
              onTap: () => ref
                  .read(canvasProvider.notifier)
                  .setSelectedToken(selected ? null : preset),
            );
          }).toList(),
        ),
      ),
    );
  }
}

final _swatches = {
  designTokenPresets[0]: const Color(0xFF3B82F6),
  designTokenPresets[1]: const Color(0xFF8B5CF6),
  designTokenPresets[2]: const Color(0xFFFAFAFA),
  designTokenPresets[3]: const Color(0xFF18181B),
};

class _TokenChip extends StatelessWidget {
  const _TokenChip({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectionBg : Colors.transparent,
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.borderStrong,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: swatch,
                borderRadius: AppRadius.sm,
                border: Border.all(color: AppColors.borderStrong),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 11,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return _SideBarSection(
      title: 'About',
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
        child: Text(
          'Centauri\nAI UI/UX Canvas & Code Generator',
          style: AppText.monoSmall,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- editor area --

class _EditorArea extends ConsumerWidget {
  const _EditorArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(canvasProvider.select((s) => s.outputMode));

    return ColoredBox(
      color: AppColors.bgBase,
      child: Column(
        children: [
          const _EditorTabBar(),
          const Divider(height: 1),
          const _CanvasToolbar(),
          Expanded(
            child: switch (mode) {
              OutputMode.design => const CanvasStage(),
              OutputMode.dev => const _DevSplitView(),
            },
          ),
          const Divider(height: 1),
          const _StatusBar(),
        ],
      ),
    );
  }
}

class _DevSplitView extends StatelessWidget {
  const _DevSplitView();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 3, child: CanvasStage()),
        SizedBox(
          width: 420,
          child: CodePanel(),
        ),
      ],
    );
  }
}

class _EditorTabBar extends ConsumerWidget {
  const _EditorTabBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(canvasProvider.select((s) => s.outputMode));

    return Container(
      height: AppColors.tabHeight,
      color: AppColors.chromeBg,
      child: Row(
        children: [
          _Tab(
            icon: Icons.brush_outlined,
            title: 'Canvas Preview',
            active: mode == OutputMode.design,
            onTap: () => ref
                .read(canvasProvider.notifier)
                .setOutputMode(OutputMode.design),
          ),
          _Tab(
            icon: Icons.code_outlined,
            title: 'index.html',
            active: mode == OutputMode.dev,
            onTap: () => ref
                .read(canvasProvider.notifier)
                .setOutputMode(OutputMode.dev),
          ),
          const Spacer(),
          const _ModeToggle(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.title,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.bgBase : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: active ? AppColors.accentPrimary : Colors.transparent,
              width: 1,
            ),
            right: const BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 12,
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Design / Dev switch ala Figma.
class _ModeToggle extends ConsumerWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(canvasProvider.select((s) => s.outputMode));
    return Container(
      height: 22,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          _ModeSegment(
            label: 'Design',
            active: mode == OutputMode.design,
            onTap: () => ref
                .read(canvasProvider.notifier)
                .setOutputMode(OutputMode.design),
          ),
          _ModeSegment(
            label: 'Dev',
            active: mode == OutputMode.dev,
            onTap: () => ref
                .read(canvasProvider.notifier)
                .setOutputMode(OutputMode.dev),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        color: active ? AppColors.accentPrimary : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 11,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CanvasToolbar extends ConsumerWidget {
  const _CanvasToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasProvider);
    final hasContent = state.generatedHtml != null;
    final wide = MediaQuery.sizeOf(context).width >= 640;

    return Container(
      height: AppColors.toolbarHeight,
      color: AppColors.bgBase,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (wide) ...[
            Text(
              hasContent ? 'canvas / index.html' : 'canvas / belum ada konten',
              style: AppText.monoSmall,
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            height: 24,
            child: SegmentedButton<ViewportMode>(
              segments: ViewportMode.values
                  .map(
                    (mode) => ButtonSegment<ViewportMode>(
                      value: mode,
                      tooltip: '${mode.label} - ${mode.widthLabel}',
                      icon: Icon(switch (mode) {
                        ViewportMode.mobile => Icons.smartphone_outlined,
                        ViewportMode.tablet => Icons.tablet_mac_outlined,
                        ViewportMode.desktop => Icons.desktop_windows_outlined,
                      }, size: 13),
                    ),
                  )
                  .toList(),
              selected: {state.viewport},
              onSelectionChanged: (selection) => ref
                  .read(canvasProvider.notifier)
                  .setViewport(selection.first),
              showSelectedIcon: false,
            ),
          ),
          if (wide) ...[
            const SizedBox(width: 12),
            _ZoomControl(zoom: state.zoom),
          ],
          const Spacer(),
          _ToolbarButton(
            icon: Icons.delete_outline,
            tooltip: 'Bersihkan canvas',
            onPressed: hasContent
                ? () => ref.read(canvasProvider.notifier).clearCanvas()
                : null,
          ),
          _ToolbarButton(
            icon: Icons.code_outlined,
            tooltip: 'Lihat kode (Dev mode)',
            onPressed: hasContent
                ? () => ref
                      .read(canvasProvider.notifier)
                      .setOutputMode(OutputMode.dev)
                : null,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _ZoomControl extends ConsumerWidget {
  const _ZoomControl({required this.zoom});

  final double zoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _ToolbarButton(
          icon: Icons.remove,
          tooltip: 'Zoom out',
          onPressed: () => ref.read(canvasProvider.notifier).zoomOut(),
        ),
        InkWell(
          onTap: () => ref.read(canvasProvider.notifier).resetZoom(),
          child: SizedBox(
            width: 44,
            height: 24,
            child: Center(
              child: Text(
                '${(zoom * 100).round()}%',
                style: AppText.monoSmall,
              ),
            ),
          ),
        ),
        _ToolbarButton(
          icon: Icons.add,
          tooltip: 'Zoom in',
          onPressed: () => ref.read(canvasProvider.notifier).zoomIn(),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 24,
      child: IconButton(
        icon: Icon(icon, size: 15),
        tooltip: tooltip,
        splashRadius: 13,
        padding: EdgeInsets.zero,
        color: AppColors.textSecondary,
        onPressed: onPressed,
      ),
    );
  }
}

class _StatusBar extends ConsumerWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasProvider);
    final providerAsync = ref.watch(providerConfigProvider);
    final providerName = providerAsync.value?.activeProvider?.name;

    return Container(
      height: AppColors.statusBarHeight,
      color: AppColors.accentPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _StatusItem(
            icon: Icons.cloud_outlined,
            text: providerName ?? 'No provider',
          ),
          const SizedBox(width: 12),
          _StatusItem(
            icon: state.isGenerating ? Icons.sync : Icons.check,
            text: state.isGenerating ? 'Generating' : 'Ready',
          ),
          if (state.isGenerating && state.generationStartedAt != null) ...[
            const SizedBox(width: 8),
            _ElapsedTicker(startedAt: state.generationStartedAt!),
          ],
          const Spacer(),
          _StatusItem(text: 'Width: ${state.viewport.widthLabel}'),
          const SizedBox(width: 12),
          _StatusItem(
            icon: Icons.layers_outlined,
            text: '${state.domTree?.nodeCount ?? 0} nodes',
          ),
          const SizedBox(width: 12),
          _StatusItem(
            icon: Icons.forum_outlined,
            text: '${state.messages.length} msgs',
          ),
        ],
      ),
    );
  }
}

/// Menampilkan durasi generate yang sedang berjalan, agar state "Generating"
/// pada model lambat tidak terasa seperti hang.
class _ElapsedTicker extends StatefulWidget {
  const _ElapsedTicker({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_ElapsedTicker> createState() => _ElapsedTickerState();
}

class _ElapsedTickerState extends State<_ElapsedTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt).inSeconds;
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;
    final label = minutes > 0
        ? '$minutes:${seconds.toString().padLeft(2, '0')}'
        : '${seconds}s';
    return Text(
      label,
      style: const TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 11,
        color: Colors.white,
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: const TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 11,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ mobile --

class _MobileShell extends ConsumerWidget {
  const _MobileShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(canvasProvider.select((s) => s.outputMode));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 34,
        title: Text(
          mode == OutputMode.design ? 'Centauri - Canvas' : 'Centauri - Code',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: const _ModeToggle(),
          ),
          IconButton(
            tooltip: 'Provider settings',
            icon: const Icon(Icons.settings_outlined, size: 18),
            onPressed: () => context.push('/provider-config'),
          ),
        ],
      ),
      body: Column(
        children: [
          const _CanvasToolbar(),
          const Divider(height: 1),
          Expanded(
            child: mode == OutputMode.design
                ? const CanvasStage()
                : const CodePanel(),
          ),
        ],
      ),
      bottomNavigationBar: const _MobileBottomNav(),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.chromeBg,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.layers_outlined,
                  label: 'Layers',
                  onTap: () =>
                      _openSheet(context, const LayersPanel(), heightFactor: 0.6),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.forum_outlined,
                  label: 'Prompt',
                  onTap: () => _openSheet(
                    context,
                    const PromptChatPanel(),
                    heightFactor: 0.75,
                  ),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.code_outlined,
                  label: 'Code',
                  onTap: () =>
                      _openSheet(context, const CodePanel(), heightFactor: 0.8),
                ),
              ),
            ],
          ),
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
      backgroundColor: AppColors.chromeBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        side: BorderSide(color: AppColors.borderStrong),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * heightFactor,
        child: child,
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.hoverBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.uiFamily,
              fontFamilyFallback: AppFonts.uiFallback,
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
