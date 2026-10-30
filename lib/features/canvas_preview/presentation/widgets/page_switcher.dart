import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/app_dialog.dart';
import '../../domain/page.dart';
import '../provider/workspace_provider.dart';

/// ScrollBehavior yang mengizinkan scroll horizontal via mouse drag, trackpad, dan touch.
class _PageSwitcherScrollBehavior extends MaterialScrollBehavior {
  const _PageSwitcherScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

/// Tab strip untuk berpindah halaman (navigasi cadangan selain link di HTML).
///
/// Tab aktif selalu ikut state ctivePageId — termasuk saat berganti lewat
/// link <a href> di dalam HTML — dan otomatis di-scroll agar terlihat.
/// Dilengkapi efek fading edge halus di kiri dan kanan saat konten terpotong scroll.
class PageSwitcherBar extends ConsumerStatefulWidget {
  const PageSwitcherBar({super.key});

  @override
  ConsumerState<PageSwitcherBar> createState() => _PageSwitcherBarState();
}

class _PageSwitcherBarState extends ConsumerState<PageSwitcherBar> {
  final ScrollController _controller = ScrollController();
  final Map<String, GlobalKey> _tabKeys = {};
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateScrollIndicators);
    // Dengarkan perubahan halaman aktif di luar build agar auto-scroll tidak
    // ikut me-rebuild tab ketika hanya penanda aktif yang berpindah.
    ref.listenManual<String?>(
      workspaceProvider.select((s) => s.activePageId),
      (_, activeId) => _ensureActiveVisible(activeId),
      fireImmediately: true,
    );
  }

  void _updateScrollIndicators() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final canLeft = position.pixels > 1.0;
    final canRight = position.pixels < (position.maxScrollExtent - 1.0);
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  /// Pastikan tab aktif kelihatan layar (mis. halaman baru jauh di ujung).
  /// Semua tab dibangun lewat [Row] (bukan ListView lazy), jadi context-nya
  /// langsung tersedia kapan pun halaman aktifnya berpindah.
  void _ensureActiveVisible(String? activeId) {
    if (activeId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final tabContext = _tabKeys[activeId]?.currentContext;
      if (tabContext == null) return;
      Scrollable.ensureVisible(
        tabContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        alignment: 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      _updateScrollIndicators();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateScrollIndicators);
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _controller.hasClients) {
      // Izinkan scroll vertikal mouse wheel digeser ke horizontal jika deltaX bernilai 0
      final delta = event.scrollDelta.dx != 0
          ? event.scrollDelta.dx
          : event.scrollDelta.dy;
      if (delta != 0) {
        final newOffset = (_controller.offset + delta).clamp(
          _controller.position.minScrollExtent,
          _controller.position.maxScrollExtent,
        );
        _controller.jumpTo(newOffset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(workspaceProvider.select((s) => s.pages));
    final activeId = ref.watch(workspaceProvider.select((s) => s.activePageId));
    if (pages.isEmpty) return const SizedBox.shrink();
    _tabKeys.removeWhere((id, _) => pages.every((p) => p.id != id));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollIndicators();
    });

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final showLeft = isRtl ? _canScrollRight : _canScrollLeft;
    final showRight = isRtl ? _canScrollLeft : _canScrollRight;

    return SizedBox(
      height: AppMetrics.toolbarHeight,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          final stops = <double>[];
          final colors = <Color>[];

          if (showLeft) {
            colors.add(Colors.transparent);
            stops.add(0.0);
            colors.add(Colors.black);
            stops.add(24.0 / bounds.width.clamp(1.0, double.infinity));
          } else {
            colors.add(Colors.black);
            stops.add(0.0);
          }

          if (showRight) {
            final rightEdge =
                1.0 - (24.0 / bounds.width.clamp(1.0, double.infinity));
            colors.add(Colors.black);
            stops.add(rightEdge.clamp(0.0, 1.0));
            colors.add(Colors.transparent);
            stops.add(1.0);
          } else {
            colors.add(Colors.black);
            stops.add(1.0);
          }

          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: colors,
            stops: stops,
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Listener(
          onPointerSignal: _handlePointerSignal,
          child: ScrollConfiguration(
            behavior: const _PageSwitcherScrollBehavior(),
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: [
                  for (final page in pages)
                    KeyedSubtree(
                      key: _tabKeys.putIfAbsent(page.id, GlobalKey.new),
                      child: _PageTab(
                        page: page,
                        active: page.id == activeId,
                        onTap: () => ref
                            .read(workspaceProvider.notifier)
                            .setActivePage(page.id),
                        onRename: () => _rename(context, ref, page),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    AppPage page,
  ) async {
    final controller = TextEditingController(text: page.name);
    final l10n = context.l10n;
    final result = await showAppDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pageRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.pageRenameHint),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      ref.read(workspaceProvider.notifier).renamePage(page.id, result);
    }
  }
}

class _PageTab extends StatelessWidget {
  const _PageTab({
    required this.page,
    required this.active,
    required this.onTap,
    required this.onRename,
  });

  final AppPage page;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onDoubleTap: onRename,
      child: Container(
        height: AppMetrics.toolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? context.palette.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            page.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.button.copyWith(
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active
                  ? context.palette.textPrimary
                  : context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
