import 'package:flutter/material.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../prompt_editor/domain/attachment.dart';
import 'attachment_preview_dialog.dart';

/// Deretan chip lampiran dengan pratinjau gambar + tombol hapus.
class AttachmentStrip extends StatelessWidget {
  const AttachmentStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  final List<Attachment> attachments;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _AttachmentChip(
          attachment: attachments[index],
          onRemove: () => onRemove(attachments[index].id),
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment, required this.onRemove});

  final Attachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Kartu: tap untuk pratinjau.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => showAttachmentPreview(context, attachment),
              child: Container(
                decoration: BoxDecoration(
                  color: context.palette.bgSunken,
                  borderRadius: AppRadius.sm,
                  border: Border.all(color: context.palette.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Thumb(attachment: attachment),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.uiFamily,
                          fontFamilyFallback: AppFonts.uiFallback,
                          fontSize: 9,
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tombol hapus: di DALAM bounds agar mudah diklik.
          Positioned(
            top: 2,
            right: 2,
            child: Tooltip(
              message: context.l10n.attachmentRemoveTooltip,
              child: GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    // Gambar raster: tampilkan sebagai thumbnail.
    if (!attachment.isText) {
      return Image.memory(
        attachment.bytes,
        width: 44,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _FileIcon(Icons.broken_image_outlined),
      );
    }
    // SVG/HTML/teks: tampilkan ikon format.
    final icon = attachment.mimeType.contains('svg')
        ? Icons.image_outlined
        : attachment.mimeType.contains('html')
        ? Icons.html
        : attachment.mimeType.contains('css')
        ? Icons.css
        : Icons.description_outlined;
    return _FileIcon(icon);
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 32,
      child: Icon(icon, size: 22, color: context.palette.textSecondary),
    );
  }
}
