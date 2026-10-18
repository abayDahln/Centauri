import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../domain/page.dart';
import '../provider/workspace_provider.dart';

/// Tab strip untuk berpindah halaman (navigasi cadangan selain link di HTML).
class PageSwitcherBar extends ConsumerWidget {
  const PageSwitcherBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(workspaceProvider.select((s) => s.pages));
    final activeId = ref.watch(workspaceProvider.select((s) => s.activePageId));
    if (pages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: pages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final page = pages[i];
          return _PageTab(
            page: page,
            active: page.id == activeId,
            onTap: () =>
                ref.read(workspaceProvider.notifier).setActivePage(page.id),
            onRename: () => _rename(context, ref, page),
          );
        },
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
