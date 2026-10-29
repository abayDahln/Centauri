import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../../app/l10n/l10n.dart';
import '../data/catalog/provider_catalog.dart';
import '../domain/catalog/provider_catalog_entry.dart';
import '../domain/entities/api_provider.dart';

/// Data logo satu provider untuk [ProviderLogo].
///
/// Prioritas render: [assetPath] (ikon PNG dari `assets/icons/`) → [brandIcon]
/// (logo brand SimpleIcons) → [textIcon] sebagai fallback bebas-asset.
class ProviderLogoData {
  const ProviderLogoData({
    this.color,
    required this.textIcon,
    this.brandIcon,
    this.assetPath,
  });

  final IconData? brandIcon;

  /// Path aset ikon, mis. `assets/icons/groq.png`. Null bila memakai
  /// [brandIcon] atau [textIcon].
  final String? assetPath;

  /// Warna brand logo. Null = provider tanpa brand dikenal; widget memakai
  /// warna teks sekunder dari palet aktif.
  final Color? color;
  final String textIcon;
}

/// Satu kartu provider di katalog (presentasi).
class ProviderCardData {
  const ProviderCardData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.logo,
    required this.entry,
  });

  final String id;
  final String name;
  final String subtitle;
  final ProviderLogoData logo;

  /// Entri katalog yang dikembalikan ke pemanggil saat kartu dipilih.
  final ProviderCatalogEntry entry;
}

/// Section katalog (header + kartu).
class ProviderSection {
  const ProviderSection({required this.title, required this.cards});

  final String title;
  final List<ProviderCardData> cards;
}

/// View-model katalog provider: memetakan id terkurasi → kartu presentasi.
///
/// Ini **satu-satunya** berkas yang mengimpor `simple_icons`; seluruh metadata
/// tampilan (logo, warna, nama) terpusat di sini.
class ProviderCatalogViewModel {
  ProviderCatalogViewModel._();

  static const List<({String title, List<String> ids})> _sections = [
    (
      title: 'Free Tier',
      ids: ['opencode', 'openrouter', 'nvidia', 'ollama-cloud', 'gemini'],
    ),
    (
      title: 'API Key',
      ids: [
        'cline',
        'command-code',
        'groq',
        'minimax',
        'mistral',
        'zai',
        'kiro-ai',
        'custom-api',
      ],
    ),
  ];

  /// Seluruh kartu (dipakai untuk pencarian lintas section).
  static List<ProviderCardData> allCards(AppLocalizations l10n) => [
    for (final section in _sections)
      for (final id in section.ids) ?_resolve(id, l10n),
  ];

  /// Kartu provider custom ("Custom API Key"). Ditampilkan paling atas di
  /// dialog pemilih provider, terpisah dari section katalog.
  static ProviderCardData customCard(AppLocalizations l10n) =>
      _resolve(kCustomCatalogId, l10n)!;

  /// Bangun section terkurasi; section tanpa kartu yang cocok akan kosong.
  static List<ProviderSection> build(AppLocalizations l10n) => [
    for (final section in _sections)
      ProviderSection(
        title: section.title,
        cards: [for (final id in section.ids) ?_resolve(id, l10n)],
      ),
  ];

  static ProviderCardData? _resolve(String id, AppLocalizations l10n) {
    final entry = ProviderCatalog.byId(id);
    if (entry == null) return null;
    return ProviderCardData(
      id: entry.id,
      name: _displayName(entry.id, entry.name),
      subtitle: _subtitleFor(l10n, entry),
      logo: _logoFor(entry.id),
      entry: entry,
    );
  }

  /// Subtitle pendek yang menjelaskan gunanya, bukan mengulang nama section.
  /// Id tanpa teks jatuh ke host Base URL agar tidak pernah kosong.
  static String _subtitleFor(
    AppLocalizations l10n,
    ProviderCatalogEntry entry,
  ) {
    return switch (entry.id) {
      'opencode' => l10n.providerSubtitleOpencode,
      'openrouter' => l10n.providerSubtitleOpenrouter,
      'nvidia' => l10n.providerSubtitleNvidia,
      'ollama-cloud' => l10n.providerSubtitleOllamaCloud,
      'gemini' => l10n.providerSubtitleGemini,
      'cline' => l10n.providerSubtitleCline,
      'command-code' => l10n.providerSubtitleCommandCode,
      'groq' => l10n.providerSubtitleGroq,
      'minimax' => l10n.providerSubtitleMinimax,
      'mistral' => l10n.providerSubtitleMistral,
      'zai' => l10n.providerSubtitleZai,
      'kiro-ai' => l10n.providerSubtitleKiro,
      'custom-api' => l10n.providerSubtitleCustom,
      _ => _hostOf(entry.baseUrl),
    };
  }

  static String _displayName(String id, String fallback) =>
      id == 'gemini' ? 'Gemini' : fallback;

  static String _hostOf(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    return uri?.host ?? baseUrl;
  }

  static ProviderLogoData _logoFor(String id) {
    switch (id) {
      case 'opencode':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.opencode,
          color: Color(0xFF1A1A1A),
          textIcon: 'OC',
        );
      case 'openrouter':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.openrouter,
          color: Color(0xFF6467F2),
          textIcon: 'OR',
        );
      case 'nvidia':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.nvidia,
          color: Color(0xFF76B900),
          textIcon: 'NV',
        );
      case 'ollama-cloud':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.ollama,
          color: Color(0xFF333333),
          textIcon: 'OL',
        );
      case 'gemini':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.googlegemini,
          color: Color(0xFF4285F4),
          textIcon: 'GE',
        );
      case 'minimax':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.minimax,
          color: Color(0xFFF23F5D),
          textIcon: 'MM',
        );
      case 'mistral':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.mistralai,
          color: Color(0xFFFF7000),
          textIcon: 'MI',
        );
      case 'zai':
        return const ProviderLogoData(
          color: Color(0xFF4E5AF2),
          textIcon: 'GL',
          assetPath: 'assets/icons/zai.png',
        );
      case 'kiro-ai':
        return const ProviderLogoData(
          color: Color(0xFF9046FF),
          textIcon: 'KR',
          assetPath: 'assets/icons/kiro.png',
        );
      case 'command-code':
        return const ProviderLogoData(
          color: Color(0xFF6D28D9),
          textIcon: 'CC',
          assetPath: 'assets/icons/commandcode.png',
        );
      case 'groq':
        return const ProviderLogoData(
          color: Color(0xFFF55036),
          textIcon: 'GQ',
          assetPath: 'assets/icons/groq.png',
        );
      case 'cline':
        return const ProviderLogoData(
          color: Color(0xFF0F1115),
          textIcon: 'CL',
          assetPath: 'assets/icons/cline.png',
        );
      case 'custom-api':
        return const ProviderLogoData(color: Color(0xFF5F6368), textIcon: 'CU');
      default:
        return const ProviderLogoData(textIcon: '?');
    }
  }
}
