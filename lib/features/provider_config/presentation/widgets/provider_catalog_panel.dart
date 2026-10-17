import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import '../../domain/catalog/provider_catalog_entry.dart';
import '../provider_catalog_view_model.dart';
import 'provider_card.dart';

/// Daftar pilihan provider (isi dialog pemilih provider).
///
/// Opsi "Custom API Key" dipin paling atas (di luar section katalog), lalu
/// kartu per section (Free Tier / API Key). Mengetuk kartu memanggil
/// [onSelected] dan pemanggil menutup dialog.
///
/// [selectedId] menandai kartu provider yang sedang dipakai, bila ada.
class ProviderCatalogPanel extends StatelessWidget {
  const ProviderCatalogPanel({
    super.key,
    required this.onSelected,
    this.selectedId,
  });

  final void Function(ProviderCatalogEntry entry) onSelected;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final custom = ProviderCatalogViewModel.customCard;
    final sections = ProviderCatalogViewModel.build();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Custom API Key selalu paling atas.
        ProviderCard(
          data: custom,
          selected: custom.id == selectedId,
          onTap: () => onSelected(custom.entry),
        ),
        const SizedBox(height: 20),
        for (final section in sections)
          if (section.cards.any((card) => card.id != custom.id)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
              child: Text(section.title, style: AppText.sectionTitle),
            ),
            // Satu kolom penuh (bukan grid) agar nama/subtitle tampil penuh.
            for (final card in section.cards.where(
              (card) => card.id != custom.id,
            )) ...[
              ProviderCard(
                data: card,
                selected: card.id == selectedId,
                onTap: () => onSelected(card.entry),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
