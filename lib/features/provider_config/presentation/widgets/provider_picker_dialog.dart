import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
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
      title: Text(context.l10n.providerPickerTitle),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      content: SizedBox(
        // Di HP dialog tidak boleh lebih lebar dari layar minus inset.
        width: math.min(420, MediaQuery.sizeOf(context).width - 80),
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
          child: Text(context.l10n.commonCancel),
        ),
      ],
    );
  }
}
