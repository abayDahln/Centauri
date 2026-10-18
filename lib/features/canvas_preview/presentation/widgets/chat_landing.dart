import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../prompt_editor/domain/attachment.dart';
import '../provider/workspace_provider.dart';
import 'ai_status_indicator.dart';
import 'attachment_preview_dialog.dart';
import 'markdown_message.dart';

/// Tampilan awal saat belum ada UI di board: percakapan biasa seperti chatbot.
/// Board disembunyikan sampai frame pertama selesai digenerate.
class ChatLanding extends ConsumerWidget {
  const ChatLanding({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceProvider);
    final messages = state.messages;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      // SelectionArea memungkinkan seleksi teks lintas pesan/blok sekaligus.
      // Warna highlight amber eksplisit agar jelas terlihat di atas bubble biru.
      child: SelectionArea(
        selectionControls: materialTextSelectionControls,
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
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: AppRadius.md,
              ),
              child: const Icon(
                Icons.brush_outlined,
                size: 22,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text('Mulai dengan pesan', style: AppText.panelTitle),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                'Tanya apa saja untuk saran desain, atau minta langsung '
                'dibuat.',
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
          padding: EdgeInsets.symmetric(
            horizontal: isUser ? 14 : 0,
            vertical: isUser ? 10 : 0,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.textPrimary
                : isError
                ? AppColors.statusError.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: isUser
                ? const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(2),
                  )
                : AppRadius.md,
            border: isError
                ? Border.all(
                    color: AppColors.statusError.withValues(alpha: 0.32),
                  )
                : null,
          ),
          // Lampiran (gambar) di atas teks; tap untuk pratinjau.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.attachments.isNotEmpty) ...[
                _MessageAttachments(
                  attachments: message.attachments,
                  onDark: isUser,
                ),
                const SizedBox(height: 8),
              ] else if (message.attachmentNames.isNotEmpty) ...[
                _AttachmentNameChips(names: message.attachmentNames),
                const SizedBox(height: 8),
              ],
              // Pesan AI dirender sebagai markdown; user/error sebagai teks.
              if (isUser)
                Text(
                  message.shownText,
                  style: const TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontFamilyFallback: AppFonts.uiFallback,
                    fontSize: 13.5,
                    height: 1.55,
                    color: Colors.white,
                  ),
                )
              else ...[
                if (!isError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Alpha',
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                MarkdownMessage(
                  text: message.text,
                  baseColor: isError
                      ? AppColors.statusError
                      : AppColors.textPrimary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Deretan thumbnail lampiran di dalam bubble pesan user.
class _MessageAttachments extends StatelessWidget {
  const _MessageAttachments({required this.attachments, required this.onDark});

  final List<Attachment> attachments;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((attachment) {
        return GestureDetector(
          onTap: () => showAttachmentPreview(context, attachment),
          child: ClipRRect(
            borderRadius: AppRadius.sm,
            child: _attachmentThumb(attachment),
          ),
        );
      }).toList(),
    );
  }

  Widget _attachmentThumb(Attachment attachment) {
    if (!attachment.isText) {
      return Image.memory(
        attachment.bytes,
        width: 120,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fileChip(attachment),
      );
    }
    return _fileChip(attachment);
  }

  Widget _fileChip(Attachment attachment) {
    final icon = attachment.mimeType.contains('svg')
        ? Icons.image_outlined
        : attachment.mimeType.contains('html')
        ? Icons.html
        : attachment.mimeType.contains('css')
        ? Icons.css
        : Icons.description_outlined;
    return Container(
      width: 120,
      height: 84,
      color: onDark ? Colors.white24 : AppColors.bgSurface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: onDark ? Colors.white : AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 9,
                color: onDark ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip nama lampiran (untuk pesan lama yang gambarnya tidak tersimpan di memori).
class _AttachmentNameChips extends StatelessWidget {
  const _AttachmentNameChips({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: names
          .map(
            (name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: AppRadius.pill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: AppFonts.uiFamily,
                      fontFamilyFallback: AppFonts.uiFallback,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
