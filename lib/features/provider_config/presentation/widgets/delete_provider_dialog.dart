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
      title: const Text('Hapus provider ini?'),
      content: Text('$label beserta data tersimpan akan dihapus permanen.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.statusError),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
