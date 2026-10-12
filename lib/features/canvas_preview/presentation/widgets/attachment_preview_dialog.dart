import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import '../../../prompt_editor/domain/attachment.dart';

/// Menampilkan dialog pratinjau lampiran (gambar besar / isi teks).
Future<void> showAttachmentPreview(
  BuildContext context,
  Attachment attachment,
) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xCC000000),
    builder: (dialogContext) => _AttachmentPreviewDialog(
      attachment: attachment,
    ),
  );
}

class _AttachmentPreviewDialog extends StatelessWidget {
  const _AttachmentPreviewDialog({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final isImage = !attachment.isText;
    return Dialog(
      backgroundColor: AppColors.bgSurface,
      insetPadding: const EdgeInsets.all(40),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(attachment: attachment),
            const Divider(height: 1),
            Flexible(
              child: isImage
                  ? _ImageBody(bytes: attachment.bytes)
                  : _TextBody(text: attachment.textContent),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.image_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sectionTitle,
            ),
          ),
          Text(_humanSize(attachment.sizeBytes), style: AppText.caption),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({required this.bytes});

  final List<int> bytes;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Gambar tidak bisa ditampilkan.',
              style: AppText.caption,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextBody extends StatelessWidget {
  const _TextBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontFamily: AppFonts.monoFamily,
          fontFamilyFallback: AppFonts.monoFallback,
          fontSize: 12,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
