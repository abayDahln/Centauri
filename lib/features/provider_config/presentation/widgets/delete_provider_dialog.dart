import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';

/// Menampilkan dialog konfirmasi hapus provider.
///
/// Mengembalikan `true` hanya bila pengguna menekan "Hapus".
Future<bool> showDeleteProviderDialog(BuildContext context, String name) async {
  final label = name.trim().isEmpty ? 'provider ini' : '"${name.trim()}"';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      title: const Text(
        'Hapus Provider',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        'Hapus $label beserta kredensial tersimpan? Tindakan ini tidak dapat '
        'dibatalkan.',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text(
            'Hapus',
            style: TextStyle(color: AppColors.statusError),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
