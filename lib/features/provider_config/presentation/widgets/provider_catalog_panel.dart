import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import '../../domain/catalog/catalog_selection.dart';
import '../provider_catalog_view_model.dart';
import 'provider_card.dart';

/// Panel katalog provider siap-pakai untuk layar Tambah/Edit Provider.
///
/// Menampilkan grid kartu per section (OAuth / Free Tier / API Key).
/// Mengetuk kartu memanggil [onSelected] agar pemanggil langsung mengisi
/// form — tanpa navigasi ke halaman katalog terpisah.
///
/// [selectedId] menandai kartu provider yang sedang dipakai form (id katalog
/// atau id preset OAuth), bila ada.
class ProviderCatalogPanel extends StatelessWidget {
  const ProviderCatalogPanel({
    super.key,
    required this.onSelected,
    this.selectedId,
  });

  final void Function(CatalogSelection selection) onSelected;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final sections = ProviderCatalogViewModel.build();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text(section.title, style: AppText.sectionTitle),
          ),
          // Satu kolom penuh (bukan grid) agar nama/subtitle tampil
          // penuh tanpa terpotong.
          for (var i = 0; i < section.cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            ProviderCard(
              data: section.cards[i],
              selected: section.cards[i].id == selectedId,
              onTap: () => onSelected(section.cards[i].selection),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
