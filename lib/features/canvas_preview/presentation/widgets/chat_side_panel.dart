import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/widgets/stitch_widgets.dart';
import '../../../history/presentation/history_panel.dart';
import '../../../prompt_editor/presentation/prompt_chat_panel.dart';

/// Panel kiri saat board aktif: punya dua tab, **Chat** dan **History**.
/// Bisa disembunyikan lewat tombol di top bar.
class ChatSidePanel extends ConsumerStatefulWidget {
  const ChatSidePanel({super.key});

  @override
  ConsumerState<ChatSidePanel> createState() => _ChatSidePanelState();
}

class _ChatSidePanelState extends ConsumerState<ChatSidePanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TabBar(
            index: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
          Expanded(
            child: _tab == 0 ? const PromptChatPanel() : const HistoryPanel(),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Chat',
            icon: Icons.forum_outlined,
            active: index == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 4),
          _TabButton(
            label: 'History',
            icon: Icons.history,
            active: index == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.accentPrimary
        : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accentSoft : Colors.transparent,
          borderRadius: AppRadius.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
