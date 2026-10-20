import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../presentation/history_provider.dart';

/// Panel riwayat ala Gemini: tombol "Chat baru", pencarian, dan daftar
/// percakapan tersimpan (dengan hapus). Membuka/membuat chat otomatis
/// mengantar ke tab Chat via [onOpenProject].
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

  void _newChat() {
    ref.read(historyProvider.notifier).startNew();
    widget.onOpenProject?.call();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);
    final projects = state.filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _NewChatButton(onTap: _newChat),
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
            context.l10n.historyRecent,
            style: context.text.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: projects.isEmpty
              ? _EmptyState(searching: state.query.trim().isNotEmpty)
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
    final l10n = context.l10n;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.historyRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.historyRenameHint),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(historyProvider.notifier).rename(id, result);
    }
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sm,
        side: BorderSide(color: context.palette.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sm,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              Icon(Icons.add, size: 16, color: context.palette.textPrimary),
              const SizedBox(width: 8),
              Text(context.l10n.historyNewChat, style: context.text.button),
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
      height: 36,
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: AppRadius.sm,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 13,
          color: context.palette.textPrimary,
        ),
        decoration: InputDecoration(
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            size: 16,
            color: context.palette.textSecondary,
          ),
          hintText: context.l10n.historySearchHint,
          hintStyle: TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 13,
            color: context.palette.textDisabled,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
        ? context.palette.primarySoft
        : _hovered
        ? context.palette.hoverBg
        : Colors.transparent;
    final foreground = widget.active
        ? context.palette.primary
        : context.palette.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 14, color: foreground),
              const SizedBox(width: 8),
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
                  tooltip: context.l10n.historyRenameTooltip,
                  onTap: widget.onRename,
                ),
                _TileAction(
                  icon: Icons.delete_outline,
                  tooltip: context.l10n.commonDelete,
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
          child: Icon(icon, size: 15, color: context.palette.textSecondary),
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
            Icon(Icons.history, size: 26, color: context.palette.textDisabled),
            const SizedBox(height: 10),
            Text(
              searching
                  ? context.l10n.historyEmptySearch
                  : context.l10n.historyEmptyList,
              textAlign: TextAlign.center,
              style: context.text.caption,
            ),
          ],
        ),
      ),
    );
  }
}
