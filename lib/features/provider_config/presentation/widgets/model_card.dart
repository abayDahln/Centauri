import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';

/// Kartu satu model pada section "Available Models" (ala 9router).
///
/// Menampilkan [label] (mono) + nama ramah sebagai subtitle. Mengetuk kartu
/// memanggil [onTap] (memilih model). Ikon salin menyalin [modelId] — id polos
/// yang dikirim ke provider — ke clipboard, bukan [label] tampilannya.
class ModelCard extends StatefulWidget {
  const ModelCard({
    super.key,
    required this.label,
    required this.name,
    required this.modelId,
    required this.onTap,
    this.selected = false,
    this.onDelete,
  });

  /// Label tampilan bergaya 9router, mis. `cbai/glm-5.2`.
  final String label;

  /// Nama ramah, mis. `GLM-5.2`.
  final String name;

  /// Id polos model yang dipakai provider (mis. `openai/gpt-5.4`). Ini yang
  /// disalin tombol salin, karena hanya bentuk inilah yang diterima API.
  final String modelId;

  final VoidCallback onTap;

  /// Kartu ini mewakili model yang sedang dipakai provider.
  final bool selected;

  /// Menghapus model dari daftar provider ini. Null berarti tidak bisa
  /// dihapus (mis. model yang sedang dipakai).
  final VoidCallback? onDelete;

  @override
  State<ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<ModelCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentSoft
                : (_hovered ? AppColors.hoverBg : AppColors.bgSurface),
            borderRadius: AppRadius.md,
            border: Border.all(
              color: selected
                  ? AppColors.accentPrimary
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: AppRadius.sm,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 17,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.monoFamily,
                        fontFamilyFallback: AppFonts.monoFallback,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (widget.onDelete != null)
                IconButton(
                  tooltip: l10n.modelCardDeleteTooltip,
                  icon: const Icon(Icons.delete_outline, size: 15),
                  color: AppColors.textDisabled,
                  splashRadius: 16,
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onDelete,
                ),
              IconButton(
                tooltip: l10n.modelCardCopyIdTooltip,
                icon: const Icon(Icons.copy_outlined, size: 15),
                color: AppColors.textDisabled,
                splashRadius: 16,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  // Id polos, bukan label: hanya id inilah yang dikenal API.
                  Clipboard.setData(ClipboardData(text: widget.modelId));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(l10n.modelCardCopied(widget.modelId)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
