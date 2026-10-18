import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import '../provider_catalog_view_model.dart';

/// Kartu provider di katalog: logo brand + nama + subtitle + badge.
///
/// Stateful hanya untuk efek hover; tidak menyimpan state bisnis.
class ProviderCard extends StatefulWidget {
  const ProviderCard({
    super.key,
    required this.data,
    required this.onTap,
    this.selected = false,
  });

  final ProviderCardData data;
  final VoidCallback onTap;

  /// Kartu ini mewakili provider yang sedang dipilih di form.
  final bool selected;

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              ProviderLogo(logo: data.logo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile logo provider: ikon aset PNG (`assets/icons/`) bila tersedia, lalu
/// ikon brand (SimpleIcons), atau inisial teks sebagai fallback.
class ProviderLogo extends StatelessWidget {
  const ProviderLogo({super.key, required this.logo});

  final ProviderLogoData logo;

  @override
  Widget build(BuildContext context) {
    final assetPath = logo.assetPath;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: logo.color.withValues(alpha: 0.10),
        borderRadius: AppRadius.md,
      ),
      alignment: Alignment.center,
      child: assetPath != null
          ? ClipRRect(
              borderRadius: AppRadius.sm,
              child: Image.asset(
                assetPath,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackText(),
              ),
            )
          : logo.brandIcon != null
          ? Icon(logo.brandIcon, size: 22, color: logo.color)
          : _fallbackText(),
    );
  }

  Widget _fallbackText() {
    return Text(
      logo.textIcon,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: logo.color,
      ),
    );
  }
}
