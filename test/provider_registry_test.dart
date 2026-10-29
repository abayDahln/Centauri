import 'dart:io';

import 'package:centauri/features/provider_config/presentation/provider_catalog_view_model.dart';
import 'package:centauri/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderCatalogViewModel', () {
    test('dua section dengan judul yang diharapkan', () {
      final titles = ProviderCatalogViewModel.build(AppLocalizationsEn())
          .map((s) => s.title)
          .toList();
      expect(titles, ['Free Tier', 'API Key']);
    });

    test('setiap section non-kosong', () {
      for (final section in ProviderCatalogViewModel.build(
        AppLocalizationsEn(),
      )) {
        expect(section.cards, isNotEmpty, reason: section.title);
      }
    });

    test('tepat 13 provider dan id unik', () {
      final cards = ProviderCatalogViewModel.allCards(AppLocalizationsEn());
      expect(cards.length, 13);
      expect(cards.map((c) => c.id).toSet().length, 13);
    });

    test('id yang diharapkan tersedia', () {
      final ids = ProviderCatalogViewModel.allCards(AppLocalizationsEn())
          .map((c) => c.id)
          .toSet();
      expect(ids, {
        'cline',
        'opencode',
        'openrouter',
        'nvidia',
        'ollama-cloud',
        'gemini',
        'command-code',
        'groq',
        'minimax',
        'mistral',
        'zai',
        'kiro-ai',
        'custom-api',
      });
    });

    test('setiap kartu menyertakan entri katalog', () {
      for (final card in ProviderCatalogViewModel.allCards(
        AppLocalizationsEn(),
      )) {
        expect(card.entry.id, card.id, reason: card.id);
      }
    });

    test('setiap kartu punya nama/subtitle/logo non-kosong', () {
      for (final card in ProviderCatalogViewModel.allCards(
        AppLocalizationsEn(),
      )) {
        expect(card.name.trim(), isNotEmpty, reason: card.id);
        expect(card.subtitle.trim(), isNotEmpty, reason: card.id);
        expect(card.logo.textIcon.trim(), isNotEmpty, reason: card.id);
      }
    });

    test('kartu Gemini memakai nama "Gemini"', () {
      final gemini = ProviderCatalogViewModel.allCards(AppLocalizationsEn())
          .firstWhere((c) => c.id == 'gemini');
      expect(gemini.name, 'Gemini');
    });

    test('setiap logo asset menunjuk file yang ada', () {
      for (final card in ProviderCatalogViewModel.allCards(
        AppLocalizationsEn(),
      )) {
        final assetPath = card.logo.assetPath;
        if (assetPath == null) continue;
        expect(
          File(assetPath).existsSync(),
          isTrue,
          reason: '${card.id}: $assetPath tidak ditemukan',
        );
      }
    });
  });
}
