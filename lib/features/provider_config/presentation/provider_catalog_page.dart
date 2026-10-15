import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme.dart';
import '../data/catalog/provider_catalog.dart';
import '../data/oauth/oauth_provider_presets.dart';
import '../domain/catalog/catalog_selection.dart';
import '../domain/catalog/provider_catalog_entry.dart';
import '../domain/oauth/oauth_provider_preset.dart';
import 'widgets/centauri_table.dart';

/// Layar katalog provider siap-pakai: tabel per kategori + pencarian.
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

  bool _matches(String name, String id) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return name.toLowerCase().contains(q) || id.toLowerCase().contains(q);
  }

  List<OAuthProviderPreset> get _oauthPresets =>
      OAuthProviderPresets.all.where((p) => !p.isCustom).toList();

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
                  'Anda tetap perlu menempelkan API key milik sendiri.',
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

    final oauth = _oauthPresets.where((p) => _matches(p.label, p.id)).toList();
    if (oauth.isNotEmpty) {
      sections.add(
        _section(
          'OAuth',
          CentauriTable<OAuthProviderPreset>(
            columns: [
              CentauriTableColumn<OAuthProviderPreset>(
                label: 'Provider',
                flex: 4,
                cell: (_, preset) => _providerCell(
                  icon: Icons.login,
                  color: AppColors.accentPrimary,
                  name: preset.label,
                  note: preset.description,
                ),
              ),
              CentauriTableColumn<OAuthProviderPreset>(
                label: 'Model default',
                flex: 3,
                cell: (_, preset) => _mono(preset.defaultModel ?? '—'),
              ),
              CentauriTableColumn<OAuthProviderPreset>(
                label: 'Aksi',
                width: 96,
                alignment: Alignment.centerRight,
                cell: (_, preset) => _pickButton(
                  onTap: () => context.pop(OAuthSelection(preset)),
                ),
              ),
            ],
            rows: oauth,
            rowKey: (preset) => preset.id,
            onRowTap: (preset) => context.pop(OAuthSelection(preset)),
          ),
        ),
      );
    }

    for (final category in ProviderCategory.values) {
      final entries = ProviderCatalog.byCategory(
        category,
      ).where((e) => _matches(e.name, e.id)).toList();
      if (entries.isEmpty) continue;
      sections.add(
        _section(
          category.label,
          CentauriTable<ProviderCatalogEntry>(
            columns: [
              CentauriTableColumn<ProviderCatalogEntry>(
                label: 'Provider',
                flex: 4,
                cell: (_, entry) => _providerCell(
                  icon: entry.icon,
                  color: entry.brandColor,
                  name: entry.name,
                  note: entry.note,
                ),
              ),
              CentauriTableColumn<ProviderCatalogEntry>(
                label: 'Model default',
                flex: 3,
                cell: (_, entry) => _mono(entry.defaultModel),
              ),
              CentauriTableColumn<ProviderCatalogEntry>(
                label: 'Endpoint',
                flex: 3,
                cell: (_, entry) => _mono(_hostOf(entry.baseUrl)),
              ),
              CentauriTableColumn<ProviderCatalogEntry>(
                label: 'Aksi',
                width: 96,
                alignment: Alignment.centerRight,
                cell: (_, entry) => _pickButton(
                  onTap: () => context.pop(ApiKeySelection(entry)),
                ),
              ),
            ],
            rows: entries,
            rowKey: (entry) => entry.id,
            onRowTap: (entry) => context.pop(ApiKeySelection(entry)),
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

  Widget _section(String title, Widget table) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
          child: Text(title, style: AppText.sectionTitle),
        ),
        table,
      ],
    );
  }

  Widget _providerCell({
    required IconData icon,
    required Color color,
    required String name,
    String? note,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.sm,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (note != null && note.isNotEmpty)
                Text(
                  note,
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
      ],
    );
  }

  Widget _mono(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: AppFonts.monoFamily,
        fontFamilyFallback: AppFonts.monoFallback,
        fontSize: 11,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _pickButton({required VoidCallback onTap}) {
    return TextButton(
      onPressed: onTap,
      child: const Text('Pilih', style: TextStyle(fontSize: 12)),
    );
  }

  static String _hostOf(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    return uri?.host ?? baseUrl;
  }
}
