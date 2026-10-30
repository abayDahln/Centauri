import 'package:flutter/material.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../prompt_editor/domain/attachment.dart';
import 'attachment_preview_dialog.dart';

/// Deretan lampiran yang menunggu dikirim: thumbnail persegi 64x64 dengan
/// tombol hapus kecil di sudut kanan atas.
///
/// Ukurannya tetap dan gambarnya mengisi penuh kartu supaya langsung terbaca,
/// bukan kartu tinggi berisi thumbnail mungil. [Wrap] dipakai agar satu
/// lampiran tidak menyisakan ruang kosong di sampingnya.
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

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final attachment in attachments)
            _AttachmentChip(
              attachment: attachment,
              onRemove: () => onRemove(attachment.id),
            ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment, required this.onRemove});

  static const double _size = 64;

  final Attachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Tooltip(
              message: attachment.name,
              child: GestureDetector(
                onTap: () => showAttachmentPreview(context, attachment),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.bgSunken,
                    borderRadius: AppRadius.md,
                  ),
                  // Garis di foreground supaya tetap terlihat di atas gambar
                  // yang mengisi penuh kartu.
                  foregroundDecoration: BoxDecoration(
                    borderRadius: AppRadius.md,
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: attachment.isText
                      ? _TextTile(attachment: attachment)
                      : Image.memory(
                          attachment.bytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _TileIcon(Icons.broken_image_outlined),
                        ),
                ),
              ),
            ),
          ),
          // Tombol hapus: kecil, di dalam batas kartu agar tetap mudah diklik
          // tanpa menutupi sebagian besar gambar.
          PositionedDirectional(
            top: 3,
            end: 3,
            child: Tooltip(
              message: context.l10n.attachmentRemoveTooltip,
              child: GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 11, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lampiran teks (SVG/HTML/CSS): ikon format + nama berkas.
class _TextTile extends StatelessWidget {
  const _TextTile({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final mime = attachment.mimeType;
    final icon = mime.contains('svg')
        ? Icons.image_outlined
        : mime.contains('html')
        ? Icons.html
        : mime.contains('css')
        ? Icons.css
        : Icons.description_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: context.palette.textSecondary),
          const SizedBox(height: 3),
          Text(
            attachment.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.uiFamily,
              fontFamilyFallback: AppFonts.uiFallback,
              fontSize: 8.5,
              height: 1.15,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, size: 20, color: context.palette.textSecondary),
    );
  }
}
