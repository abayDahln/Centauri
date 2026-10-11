import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../presentation/history_provider.dart';

/// Panel riwayat ala Gemini: tombol "Chat baru", pencarian, dan daftar
/// percakapan tersimpan (dengan hapus).
class HistoryPanel extends ConsumerStatefulWidget {
  const HistoryPanel({super.key, this.onOpenProject});

  /// Dipanggil setelah proyek dibuka (untuk menutup/menggeser layout).
  final VoidCallback? onOpenProject;

  @override
  ConsumerState<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends ConsumerState<HistoryPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _open(String id) async {
    await ref.read(historyProvider.notifier).open(id);
    widget.onOpenProject?.call();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);
    final projects = state.filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PanelHeader(title: 'Riwayat'),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _NewChatButton(
            onTap: () => ref.read(historyProvider.notifier).startNew(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _SearchField(
            controller: _searchController,
            onChanged: (value) =>
                ref.read(historyProvider.notifier).setQuery(value),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Terbaru',
            style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: projects.isEmpty
              ? _EmptyState(
                  searching: state.query.trim().isNotEmpty,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final active = project.id == state.activeProjectId;
                    return _ProjectTile(
                      title: project.title.isEmpty
                          ? project.preview
                          : project.title,
                      active: active,
                      onTap: () => _open(project.id),
                      onDelete: () =>
                          ref.read(historyProvider.notifier).delete(project.id),
                      onRename: () => _promptRename(project.id, project.title),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _promptRename(String id, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ganti nama'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama percakapan'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(historyProvider.notifier).rename(id, result);
    }
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

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.accentPrimary,
              ),
              const SizedBox(width: 10),
              Text(
                'Chat baru',
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: AppRadius.pill,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          hintText: 'Cari percakapan',
          hintStyle: TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 13,
            color: AppColors.textDisabled,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _ProjectTile extends StatefulWidget {
  const _ProjectTile({
    required this.title,
    required this.active,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  @override
  State<_ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<_ProjectTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.active
        ? AppColors.accentSoft
        : _hovered
        ? AppColors.hoverBg
        : Colors.transparent;
    final foreground = widget.active
        ? AppColors.accentPrimary
        : AppColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 15, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontFamilyFallback: AppFonts.uiFallback,
                    fontSize: 13,
                    fontWeight: widget.active
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: foreground,
                  ),
                ),
              ),
              if (_hovered) ...[
                _TileAction(
                  icon: Icons.edit_outlined,
                  tooltip: 'Ganti nama',
                  onTap: widget.onRename,
                ),
                _TileAction(
                  icon: Icons.delete_outline,
                  tooltip: 'Hapus',
                  onTap: widget.onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  const _TileAction({
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
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history,
              size: 26,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 10),
            Text(
              searching
                  ? 'Tidak ada percakapan yang cocok.'
                  : 'Belum ada percakapan tersimpan.\nMulai dari "Chat baru".',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}
