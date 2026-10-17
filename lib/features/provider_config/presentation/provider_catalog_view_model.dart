import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../../app/config/theme.dart';
import '../data/catalog/provider_catalog.dart';
import '../data/oauth/oauth_provider_presets.dart';
import '../domain/catalog/catalog_selection.dart';
import '../domain/oauth/oauth_provider_preset.dart';

/// Data logo satu provider untuk [ProviderLogo].
///
/// Prioritas render: [assetPath] (ikon PNG dari `assets/icons/`) → [brandIcon]
/// (logo brand SimpleIcons) → [textIcon] sebagai fallback bebas-asset.
class ProviderLogoData {
  const ProviderLogoData({
    required this.color,
    required this.textIcon,
    this.brandIcon,
    this.assetPath,
  });

  final IconData? brandIcon;

  /// Path aset ikon, mis. `assets/icons/claude.png`. Null bila memakai
  /// [brandIcon] atau [textIcon].
  final String? assetPath;
  final Color color;
  final String textIcon;
}

/// Satu kartu provider di katalog (presentasi).
class ProviderCardData {
  const ProviderCardData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.logo,
    required this.selection,
    this.isExperimental = false,
    this.isTokenOnly = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final ProviderLogoData logo;

  /// Hasil yang dikembalikan ke pemanggil saat kartu dipilih.
  final CatalogSelection selection;

  final bool isExperimental;
  final bool isTokenOnly;
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
      title: 'OAuth',
      ids: [
        'claude-code',
        'antigravity',
        'qoder',
        'openai-codex',
        'github-copilot',
        'cursor',
        'kilo-code',
        'cline',
        'codebuddy',
        'zai-glm',
        'grok-cli',
      ],
    ),
    (
      title: 'Free Tier',
      ids: ['opencode', 'openrouter', 'nvidia', 'ollama-cloud', 'gemini'],
    ),
    (
      title: 'API Key',
      ids: [
        'command-code',
        'groq',
        'minimax',
        'mistral',
        'kiro-ai',
        'custom-api',
      ],
    ),
  ];

  /// Seluruh kartu (dipakai untuk pencarian lintas section).
  static List<ProviderCardData> allCards() => [
    for (final section in _sections)
      for (final id in section.ids) ?_resolve(id),
  ];

  /// Bangun section terkurasi; section tanpa kartu yang cocok akan kosong.
  static List<ProviderSection> build() => [
    for (final section in _sections)
      ProviderSection(
        title: section.title,
        cards: [for (final id in section.ids) ?_resolve(id)],
      ),
  ];

  static ProviderCardData? _resolve(String id) {
    final preset = OAuthProviderPresets.byId(id);
    if (preset != null && !preset.isCustom) {
      return ProviderCardData(
        id: preset.id,
        name: _displayName(preset.id, preset.label),
        subtitle: _presetSubtitle(preset),
        logo: _logoFor(preset.id),
        selection: OAuthSelection(preset),
        isExperimental: preset.isExperimental,
        isTokenOnly: preset.isTokenOnly,
      );
    }
    final entry = ProviderCatalog.byId(id);
    if (entry != null) {
      return ProviderCardData(
        id: entry.id,
        name: _displayName(entry.id, entry.name),
        subtitle: entry.note ?? _hostOf(entry.baseUrl),
        logo: _logoFor(entry.id),
        selection: ApiKeySelection(entry),
      );
    }
    return null;
  }

  static String _displayName(String id, String fallback) =>
      id == 'google-gemini' || id == 'gemini' ? 'Gemini' : fallback;

  static String _presetSubtitle(OAuthProviderPreset preset) =>
      preset.isTokenOnly ? 'Login • tanpa chat' : 'Login OAuth';

  static String _hostOf(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    return uri?.host ?? baseUrl;
  }

  static ProviderLogoData _logoFor(String id) {
    switch (id) {
      case 'claude-code':
        return const ProviderLogoData(
          color: Color(0xFFD97757),
          textIcon: 'CL',
          assetPath: 'assets/icons/claude.png',
        );
      case 'github-copilot':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.githubcopilot,
          color: Color(0xFF181717),
          textIcon: 'GH',
        );
      case 'cursor':
        return const ProviderLogoData(
          brandIcon: SimpleIcons.cursor,
          color: Color(0xFF1A1A1A),
          textIcon: 'CU',
        );
      case 'cline':
        return const ProviderLogoData(
          color: Color(0xFF14B8A6),
          textIcon: 'CL',
          assetPath: 'assets/icons/cline.png',
        );
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
      case 'google-gemini':
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
      case 'antigravity':
        return const ProviderLogoData(
          color: Color(0xFF7C4DFF),
          textIcon: 'AG',
          assetPath: 'assets/icons/antigravity.png',
        );
      case 'qoder':
        return const ProviderLogoData(
          color: Color(0xFF5B5BD6),
          textIcon: 'Q',
          assetPath: 'assets/icons/qoder.png',
        );
      case 'openai-codex':
        return const ProviderLogoData(
          color: Color(0xFF10A37F),
          textIcon: 'CX',
          assetPath: 'assets/icons/codex.png',
        );
      case 'kilo-code':
        return const ProviderLogoData(
          color: Color(0xFFFF6B35),
          textIcon: 'KC',
          assetPath: 'assets/icons/kilo.png',
        );
      case 'codebuddy':
        return const ProviderLogoData(
          color: Color(0xFF0052D9),
          textIcon: 'CB',
          assetPath: 'assets/icons/codebuddy.png',
        );
      case 'zai-glm':
        return const ProviderLogoData(
          color: Color(0xFF4E5AF2),
          textIcon: 'GL',
          assetPath: 'assets/icons/zai.png',
        );
      case 'grok-cli':
        return const ProviderLogoData(
          color: Color(0xFF1A1A1A),
          textIcon: 'GK',
          assetPath: 'assets/icons/grok.png',
        );
      case 'kiro':
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
      case 'custom-api':
        return const ProviderLogoData(color: Color(0xFF5F6368), textIcon: 'CU');
      default:
        return const ProviderLogoData(
          color: AppColors.textSecondary,
          textIcon: '?',
        );
    }
  }
}
