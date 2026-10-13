import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/widgets/stitch_widgets.dart';
import '../../../history/presentation/history_panel.dart';
import '../../../prompt_editor/presentation/prompt_chat_panel.dart';

/// Tab yang sedang aktif di [ChatSidePanel]: 0 Chat, 1 History.
/// Dipakai bersama agar bagian lain (mis. [PromptBar]) bisa memaksa panel
/// berpindah ke tab Chat saat user mengirim prompt.
enum PanelTab { chat, history }

final panelTabProvider = NotifierProvider<PanelTabNotifier, PanelTab>(
  PanelTabNotifier.new,
);

class PanelTabNotifier extends Notifier<PanelTab> {
  @override
  PanelTab build() => PanelTab.chat;

  void select(PanelTab tab) => state = tab;
}

/// Visibilitas panel (Chat · History · Layers). Dipakai bersama agar PromptBar
/// bisa membuka panel ke tab Chat saat user mengirim prompt.
final panelVisibleProvider = NotifierProvider<PanelVisibleNotifier, bool>(
  PanelVisibleNotifier.new,
);

class PanelVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;

  void toggle() => state = !state;

  /// Tampilkan panel (tidak menutup bila sudah terbuka).
  void show() => state = true;
}

/// Panel kiri saat board aktif: dua tab, **Chat** dan **History**.
/// Bisa disembunyikan lewat tombol menu di top bar.
class ChatSidePanel extends ConsumerWidget {
  const ChatSidePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(panelTabProvider);
    return SoftPanel(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TabBar(
            index: tab.index,
            onChanged: (value) =>
                ref.read(panelTabProvider.notifier).select(PanelTab.values[value]),
          ),
          Expanded(
            child: switch (tab) {
              PanelTab.chat => const PromptChatPanel(),
              PanelTab.history => const HistoryPanel(),
            },
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Chat',
              icon: Icons.forum_outlined,
              active: index == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _TabButton(
              label: 'History',
              icon: Icons.history,
              active: index == 1,
              onTap: () => onChanged(1),
            ),
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
    final color = active ? AppColors.accentPrimary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accentSoft : Colors.transparent,
          borderRadius: AppRadius.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
