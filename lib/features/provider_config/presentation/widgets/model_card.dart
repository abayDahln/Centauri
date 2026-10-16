import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/config/theme.dart';

/// Kartu satu model pada section "Available Models" (ala 9router).
///
/// Menampilkan label `<alias>/<id>` (mono) + nama ramah sebagai subtitle.
/// Mengetuk kartu memanggil [onTap] (memilih model). Ikon salin menyalin id
/// polos ke clipboard.
class ModelCard extends StatefulWidget {
  const ModelCard({
    super.key,
    required this.label,
    required this.name,
    required this.onTap,
    this.selected = false,
  });

  /// Label tampilan bergaya 9router, mis. `cbai/glm-5.2`.
  final String label;

  /// Nama ramah, mis. `GLM-5.2`.
  final String name;

  final VoidCallback onTap;

  /// Kartu ini mewakili model yang sedang dipakai provider.
  final bool selected;

  @override
  State<ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<ModelCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
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
                ? AppColors.accentPrimary.withValues(alpha: 0.08)
                : (_hovered ? AppColors.hoverBg : AppColors.bgSurface),
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: selected
                  ? AppColors.accentPrimary
                  : (_hovered
                        ? AppColors.accentPrimary
                        : AppColors.borderSubtle),
            ),
            boxShadow: _hovered ? AppColors.shadowSoft : null,
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
              IconButton(
                tooltip: 'Salin id model',
                icon: const Icon(Icons.copy_outlined, size: 15),
                color: AppColors.textDisabled,
                splashRadius: 16,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.label));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          'Disalin: ${widget.label}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: AppColors.bgElevated,
                        behavior: SnackBarBehavior.floating,
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
