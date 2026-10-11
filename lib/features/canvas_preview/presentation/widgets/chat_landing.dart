import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../provider/canvas_provider.dart';
import 'ai_status_indicator.dart';
import 'markdown_message.dart';

/// Tampilan awal saat belum ada UI di board: percakapan biasa seperti chatbot.
/// Board disembunyikan sampai frame pertama selesai digenerate.
class ChatLanding extends ConsumerWidget {
  const ChatLanding({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasProvider);
    final messages = state.messages;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      // SelectionArea memungkinkan seleksi teks lintas pesan/blok sekaligus.
      child: SelectionArea(
        child: messages.isEmpty && !state.isGenerating
            ? const _Welcome()
            : ListView.separated(
                // Padding bawah ekstra agar pesan terakhir tidak tertimpa
                // kartu PromptBar yang mengambang di bawah.
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 180),
                itemCount: messages.length + (state.isGenerating ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index >= messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: AiStatusIndicator(),
                    );
                  }
                  return _Bubble(message: messages[index]);
                },
              ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: AppRadius.lg,
              ),
              child: const Icon(
                Icons.brush_outlined,
                size: 26,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Mulai dengan sebuah prompt',
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                'Tanya apa saja untuk saran desain, atau minta langsung sebuah UI. '
                'Begitu UI dibuat, board akan muncul dan menampilkan hasilnya.',
                textAlign: TextAlign.center,
                style: AppText.uiSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final CanvasMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final isError = message.role == ChatRole.error;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.accentPrimary
                : isError
                ? const Color(0xFFFCEEEE)
                : AppColors.bgSunken,
            borderRadius: AppRadius.lg,
            border: isError
                ? Border.all(color: AppColors.statusError)
                : null,
          ),
          // Pesan AI dirender sebagai markdown; pesan user/error sebagai teks.
          child: isUser
              ? Text(
                  message.text,
                  style: const TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontFamilyFallback: AppFonts.uiFallback,
                    fontSize: 13.5,
                    height: 1.55,
                    color: Colors.white,
                  ),
                )
              : MarkdownMessage(
                  text: message.text,
                  baseColor: isError
                      ? AppColors.statusError
                      : AppColors.textPrimary,
                ),
        ),
      ),
    );
  }
}
