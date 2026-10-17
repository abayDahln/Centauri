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
                        if (data.isExperimental)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: _ExperimentalDot(),
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
              if (data.isTokenOnly) ...[
                const SizedBox(width: 8),
                const _TokenChip(),
              ],
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

class _ExperimentalDot extends StatelessWidget {
  const _ExperimentalDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Layanan tidak resmi — bisa berubah sewaktu-waktu',
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.statusWarning,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Hanya login — chat belum didukung',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.bgSunken,
          borderRadius: AppRadius.sm,
        ),
        child: const Text(
          'token',
          style: TextStyle(
            fontFamily: AppFonts.monoFamily,
            fontFamilyFallback: AppFonts.monoFallback,
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
