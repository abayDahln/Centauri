import 'package:flutter/material.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/l10n/l10n.dart';

/// Menampilkan dialog konfirmasi hapus provider.
///
/// Mengembalikan `true` hanya bila pengguna menekan "Hapus".
Future<bool> showDeleteProviderDialog(BuildContext context, String name) async {
  final l10n = context.l10n;
  final label = name.trim().isEmpty
      ? l10n.providerDeleteTargetFallback
      : '"${name.trim()}"';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.providerDeleteTitle),
      content: Text(l10n.providerDeleteBody(label)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: context.palette.statusError,
          ),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
