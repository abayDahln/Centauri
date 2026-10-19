import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';

/// Label field form (12px, secondary) — dipakai konsisten di kartu setelan.
///
/// [trailing] opsional untuk penanda tambahan, mis. ikon gembok saat nilai
/// field terkunci.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  static const TextStyle _style = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    if (trailing == null) return Text(text, style: _style);
    return Row(
      children: [
        Text(text, style: _style),
        const Spacer(),
        trailing!,
      ],
    );
  }
}

/// Field pilihan bergaya input: label di atas, kotak yang diketuk untuk
/// membuka dialog pemilih.
///
/// Dipakai untuk "Provider" dan "Model" — nilainya dipilih lewat dialog, bukan
/// diketik manual.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.enabled = true,
    this.valueStyle,
    this.labelTrailing,
    this.trailing,
  });

  /// Label field (nama benda).
  final String label;

  /// Nilai terpilih; string kosong berarti belum ada pilihan.
  final String value;

  /// Teks petunjuk saat [value] kosong.
  final String hint;

  final VoidCallback onTap;
  final bool enabled;
  final TextStyle? valueStyle;

  /// Penanda pada label (mis. ikon gembok).
  final Widget? labelTrailing;

  /// Widget di kanan kotak pilihan (mis. tombol "Test"), tingginya otomatis
  /// disamakan dengan kotak.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    final Color textColor;
    if (!enabled) {
      textColor = AppColors.textDisabled;
    } else {
      textColor = hasValue ? AppColors.textPrimary : AppColors.textDisabled;
    }

    final Widget box = InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.md,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        // Border dan isian mengikuti TextFormField: aktif putih, nonaktif
        // tenggelam. Garisnya sama tipis supaya field pilihan dan field teks
        // terbaca sebagai satu keluarga kontrol.
        decoration: BoxDecoration(
          color: enabled ? AppColors.inputBg : AppColors.bgSunken,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: AppRadius.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (valueStyle ?? const TextStyle(fontSize: 13)).copyWith(
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.expand_more,
              size: 18,
              color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );

    final side = trailing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label, trailing: labelTrailing),
        const SizedBox(height: 8),
        if (side == null)
          box
        else
          // IntrinsicHeight + stretch menyamakan tinggi tombol dengan kotak
          // pilihan tanpa angka tinggi yang di-hardcode.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: box),
                const SizedBox(width: 8),
                side,
              ],
            ),
          ),
      ],
    );
  }
}
