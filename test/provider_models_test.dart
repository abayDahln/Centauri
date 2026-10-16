import 'package:centauri/features/provider_config/data/catalog/provider_models.dart';
import 'package:centauri/features/provider_config/data/oauth/oauth_provider_presets.dart';
import 'package:centauri/features/provider_config/presentation/provider_catalog_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Provider yang sengaja TIDAK punya daftar model hardcode (pengguna mengisi
/// Base URL + model sendiri).
const _noStaticModels = {'custom-api', 'custom-oauth'};

void main() {
  group('ProviderModelCatalog integrity', () {
    test('setiap set punya alias non-kosong & minimal satu model', () {
      expect(ProviderModelCatalog.providerIds, isNotEmpty);
      for (final id in ProviderModelCatalog.providerIds) {
        final set = ProviderModelCatalog.forProvider(id)!;
        expect(set.alias.trim(), isNotEmpty, reason: id);
        expect(set.models, isNotEmpty, reason: id);
      }
    });

    test('id model unik dalam satu provider', () {
      for (final id in ProviderModelCatalog.providerIds) {
        final set = ProviderModelCatalog.forProvider(id)!;
        final ids = set.models.map((m) => m.id).toList();
        expect(ids.toSet().length, ids.length, reason: id);
      }
    });

    test('id model tidak menyimpan bentuk label (alias/id)', () {
      // Sebagian provider memang punya namespace sendiri di id upstream
      // (mis. NVIDIA memakai `nvidia/…`), jadi pengecekan hanya menandai
      // id yang menyerupai label `<alias>/<id-lain-di-set-yang-sama>`.
      for (final id in ProviderModelCatalog.providerIds) {
        final set = ProviderModelCatalog.forProvider(id)!;
        final ids = set.models.map((m) => m.id).toSet();
        final prefix = '${set.alias}/';
        for (final model in set.models) {
          expect(model.id.trim(), isNotEmpty, reason: id);
          expect(model.name.trim(), isNotEmpty, reason: id);
          if (model.id.startsWith(prefix)) {
            final remainder = model.id.substring(prefix.length);
            expect(
              ids.contains(remainder),
              isFalse,
              reason:
                  '$id → ${model.id} tampak menyimpan label, bukan id polos',
            );
          }
        }
      }
    });

    test('label tampilan memakai format alias/id', () {
      final set = ProviderModelCatalog.forProvider('codebuddy')!;
      final model = set.models.firstWhere((m) => m.id == 'glm-5.2');
      expect(set.label(model), 'cbai/glm-5.2');

      final cline = ProviderModelCatalog.forProvider('cline')!;
      final opus = cline.models.firstWhere(
        (m) => m.id == 'anthropic/claude-opus-4.7',
      );
      expect(cline.label(opus), 'cl/anthropic/claude-opus-4.7');
    });

    test('forProvider(null) & id tak dikenal mengembalikan null', () {
      expect(ProviderModelCatalog.forProvider(null), isNull);
      expect(ProviderModelCatalog.forProvider('tidak-ada'), isNull);
    });

    test('setiap kartu di panel katalog punya daftar model', () {
      for (final card in ProviderCatalogViewModel.allCards()) {
        if (_noStaticModels.contains(card.id)) continue;
        expect(
          ProviderModelCatalog.forProvider(card.id),
          isNotNull,
          reason: 'kartu ${card.id} tidak punya daftar model hardcode',
        );
      }
    });

    test('setiap preset OAuth non-custom punya daftar model', () {
      for (final preset in OAuthProviderPresets.all.where(
        (p) => !p.isCustom,
      )) {
        expect(
          ProviderModelCatalog.forProvider(preset.id),
          isNotNull,
          reason: 'preset ${preset.id} tidak punya daftar model hardcode',
        );
      }
    });
  });
}
