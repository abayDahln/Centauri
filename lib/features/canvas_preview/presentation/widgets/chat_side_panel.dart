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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: AppColors.toolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              AppTab(
                label: 'Chat',
                active: tab == PanelTab.chat,
                onTap: () =>
                    ref.read(panelTabProvider.notifier).select(PanelTab.chat),
              ),
              AppTab(
                label: 'Riwayat',
                active: tab == PanelTab.history,
                onTap: () => ref
                    .read(panelTabProvider.notifier)
                    .select(PanelTab.history),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (tab) {
            PanelTab.chat => const PromptChatPanel(),
            // Buka/buat chat dari History langsung mengantar ke tab Chat.
            PanelTab.history => HistoryPanel(
              onOpenProject: () =>
                  ref.read(panelTabProvider.notifier).select(PanelTab.chat),
            ),
          },
        ),
      ],
    );
  }
}
