import 'package:centauri/features/provider_config/domain/catalog/catalog_selection.dart';
import 'package:centauri/features/provider_config/presentation/provider_catalog_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderCatalogViewModel', () {
    test('tiga section dengan judul yang diharapkan', () {
      final titles = ProviderCatalogViewModel.build()
          .map((s) => s.title)
          .toList();
      expect(titles, ['OAuth', 'Free Tier', 'API Key']);
    });

    test('setiap section non-kosong', () {
      for (final section in ProviderCatalogViewModel.build()) {
        expect(section.cards, isNotEmpty, reason: section.title);
      }
    });

    test('tepat 22 provider dan id unik', () {
      final cards = ProviderCatalogViewModel.allCards();
      expect(cards.length, 22);
      expect(cards.map((c) => c.id).toSet().length, 22);
    });

    test('id yang diharapkan tersedia', () {
      final ids = ProviderCatalogViewModel.allCards().map((c) => c.id).toSet();
      expect(ids, {
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
        'kiro',
        'opencode',
        'openrouter',
        'nvidia',
        'ollama-cloud',
        'google-gemini',
        'command-code',
        'groq',
        'minimax',
        'mistral',
        'custom-api',
      });
    });

    test('tipe selection sesuai sumber', () {
      const oauthIds = {
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
        'kiro',
        'google-gemini',
      };
      for (final card in ProviderCatalogViewModel.allCards()) {
        if (oauthIds.contains(card.id)) {
          expect(card.selection, isA<OAuthSelection>(), reason: card.id);
        } else {
          expect(card.selection, isA<ApiKeySelection>(), reason: card.id);
        }
      }
    });

    test('setiap kartu punya nama/subtitle/logo non-kosong', () {
      for (final card in ProviderCatalogViewModel.allCards()) {
        expect(card.name.trim(), isNotEmpty, reason: card.id);
        expect(card.subtitle.trim(), isNotEmpty, reason: card.id);
        expect(card.logo.textIcon.trim(), isNotEmpty, reason: card.id);
      }
    });

    test('kartu Gemini memakai nama "Gemini"', () {
      final gemini = ProviderCatalogViewModel.allCards().firstWhere(
        (c) => c.id == 'google-gemini',
      );
      expect(gemini.name, 'Gemini');
    });
  });
}
