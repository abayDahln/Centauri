import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/widgets/stitch_widgets.dart';
import '../../../history/presentation/history_panel.dart';
import '../../../prompt_editor/presentation/prompt_chat_panel.dart';
import '../provider/canvas_provider.dart';
import 'layers_panel.dart';

/// Panel kiri saat board aktif: tiga tab, **Chat**, **History**, **Layers**.
/// Bisa disembunyikan lewat tombol menu di top bar.
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
            child: switch (_tab) {
              0 => const PromptChatPanel(),
              1 => const HistoryPanel(),
              _ => const _LayersTab(),
            },
          ),
        ],
      ),
    );
  }
}

/// Konten tab Layers: tree DOM frame aktif.
class _LayersTab extends ConsumerWidget {
  const _LayersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTree = ref.watch(
      canvasProvider.select((s) => s.activeFrame?.domTree != null),
    );
    if (!hasTree) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pilih frame yang sudah dirender untuk melihat layers.\n\n'
            'Klik komponen di canvas untuk memilihnya.',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
        ),
      );
    }
    return const LayersPanel();
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
          const SizedBox(width: 2),
          Expanded(
            child: _TabButton(
              label: 'Layers',
              icon: Icons.layers_outlined,
              active: index == 2,
              onTap: () => onChanged(2),
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
