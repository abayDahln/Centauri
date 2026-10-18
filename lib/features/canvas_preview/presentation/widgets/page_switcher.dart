import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../domain/page.dart';
import '../provider/workspace_provider.dart';

/// Tab strip untuk berpindah halaman (navigasi cadangan selain link di HTML).
///
/// Tab aktif selalu ikut state `activePageId` — termasuk saat berganti lewat
/// link `<a href>` di dalam HTML — dan otomatis di-scroll agar terlihat.
class PageSwitcherBar extends ConsumerStatefulWidget {
  const PageSwitcherBar({super.key});

  @override
  ConsumerState<PageSwitcherBar> createState() => _PageSwitcherBarState();
}

class _PageSwitcherBarState extends ConsumerState<PageSwitcherBar> {
  final ScrollController _controller = ScrollController();
  final Map<String, GlobalKey> _tabKeys = {};

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan halaman aktif di luar build agar auto-scroll tidak
    // ikut me-rebuild tab ketika hanya penanda aktif yang berpindah.
    ref.listenManual<String?>(
      workspaceProvider.select((s) => s.activePageId),
      (_, activeId) => _ensureActiveVisible(activeId),
      fireImmediately: true,
    );
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
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(workspaceProvider.select((s) => s.pages));
    final activeId = ref.watch(workspaceProvider.select((s) => s.activePageId));
    if (pages.isEmpty) return const SizedBox.shrink();
    _tabKeys.removeWhere((id, _) => pages.every((p) => p.id != id));

    return SizedBox(
      height: 38,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              for (final page in pages) ...[
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
                const SizedBox(width: 6),
              ],
            ],
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
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah nama halaman'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama halaman'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Simpan'),
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
    return Tooltip(
      message: '${page.slug}\n(klik dua kali untuk ubah nama)',
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onRename,
        borderRadius: AppRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.accentSoft : AppColors.bgSurface,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: active ? AppColors.accentPrimary : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 13,
                color: active
                    ? AppColors.accentPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  page.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontFamilyFallback: AppFonts.uiFallback,
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }
}
