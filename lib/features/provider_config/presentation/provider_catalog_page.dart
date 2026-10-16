import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme.dart';
import '../domain/catalog/catalog_selection.dart';
import 'provider_catalog_view_model.dart';
import 'widgets/provider_card.dart';

/// Layar katalog provider siap-pakai: grid kartu per section + pencarian.
///
/// Menutup layar sambil mengembalikan [CatalogSelection] ke pemanggil.
class ProviderCatalogPage extends StatefulWidget {
  const ProviderCatalogPage({super.key});

  @override
  State<ProviderCatalogPage> createState() => _ProviderCatalogPageState();
}

class _ProviderCatalogPageState extends State<ProviderCatalogPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ProviderCardData card) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return card.name.toLowerCase().contains(q) ||
        card.id.toLowerCase().contains(q) ||
        card.subtitle.toLowerCase().contains(q);
  }

  void _select(CatalogSelection selection) => context.pop(selection);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Katalog Provider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pilih provider untuk mengisi Base URL dan model secara otomatis. '
                  'Anda tetap perlu menempelkan API key atau login sendiri.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari provider...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildSections(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final sections = <Widget>[];

    for (final section in ProviderCatalogViewModel.build()) {
      final cards = section.cards.where(_matches).toList();
      if (cards.isEmpty) continue;
      sections.add(
        _section(
          section.title,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 88,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return ProviderCard(
                data: card,
                onTap: () => _select(card.selection),
              );
            },
          ),
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'Tidak ada provider yang cocok.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return sections;
  }

  Widget _section(String title, Widget grid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
          child: Text(title, style: AppText.sectionTitle),
        ),
        grid,
      ],
    );
  }
}
