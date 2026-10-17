import 'package:flutter/material.dart';

import '../../domain/catalog/provider_catalog_entry.dart';
import 'provider_catalog_panel.dart';

/// Dialog pemilih provider: "Custom API Key" paling atas, lalu template
/// katalog (Free Tier / API Key).
///
/// Mengembalikan entri katalog yang dipilih, atau null bila dibatalkan.
Future<ProviderCatalogEntry?> showProviderPickerDialog(
  BuildContext context, {
  String? selectedId,
}) {
  return showDialog<ProviderCatalogEntry>(
    context: context,
    builder: (dialogContext) => _ProviderPickerDialog(selectedId: selectedId),
  );
}

class _ProviderPickerDialog extends StatelessWidget {
  const _ProviderPickerDialog({this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Provider'),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: SingleChildScrollView(
            child: ProviderCatalogPanel(
              onSelected: (entry) => Navigator.of(context).pop(entry),
              selectedId: selectedId,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
