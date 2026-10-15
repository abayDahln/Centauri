import 'package:centauri/features/provider_config/data/catalog/provider_catalog.dart';
import 'package:centauri/features/provider_config/data/oauth/oauth_provider_presets.dart';
import 'package:centauri/features/provider_config/domain/catalog/provider_catalog_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderCatalog integrity', () {
    test('ids are unique', () {
      final ids = ProviderCatalog.all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('baseUrls are unique (case-insensitive)', () {
      final urls = ProviderCatalog.all
          .map((e) => e.baseUrl.toLowerCase())
          .toList();
      expect(urls.toSet().length, urls.length);
    });

    test('every baseUrl is a valid http(s) URL with authority', () {
      for (final entry in ProviderCatalog.all) {
        final uri = Uri.tryParse(entry.baseUrl);
        expect(uri, isNotNull, reason: '${entry.id}: baseUrl tidak valid');
        expect(uri!.hasScheme, isTrue, reason: '${entry.id}: tanpa skema');
        expect(
          uri.scheme == 'http' || uri.scheme == 'https',
          isTrue,
          reason: '${entry.id}: skema harus http/https',
        );
        expect(
          uri.hasAuthority,
          isTrue,
          reason: '${entry.id}: tanpa authority/host',
        );
      }
    });

    test('baseUrl is a root (never a full endpoint path)', () {
      for (final entry in ProviderCatalog.all) {
        final url = entry.baseUrl.toLowerCase();
        expect(
          url.endsWith('/chat/completions'),
          isFalse,
          reason: '${entry.id}: baseUrl harus root, bukan endpoint penuh',
        );
        expect(
          url.endsWith('/models'),
          isFalse,
          reason: '${entry.id}: baseUrl tidak boleh berisi /models',
        );
      }
    });

    test('required display fields are non-empty', () {
      for (final entry in ProviderCatalog.all) {
        expect(entry.name.trim().isNotEmpty, isTrue, reason: entry.id);
        expect(entry.defaultModel.trim().isNotEmpty, isTrue, reason: entry.id);
        expect(entry.textIcon.trim().isNotEmpty, isTrue, reason: entry.id);
        expect(
          entry.textIcon.length <= 2,
          isTrue,
          reason: '${entry.id}: textIcon maksimal 2 huruf',
        );
      }
    });

    test('brand color is fully opaque', () {
      for (final entry in ProviderCatalog.all) {
        expect(entry.brandColor.a, 1.0, reason: entry.id);
      }
    });

    test('every category has at least one entry', () {
      for (final category in ProviderCategory.values) {
        expect(
          ProviderCatalog.byCategory(category).isNotEmpty,
          isTrue,
          reason: 'Kategori ${category.name} kosong',
        );
      }
    });

    test('local providers have no apiKeyUrl', () {
      for (final entry in ProviderCatalog.byCategory(ProviderCategory.local)) {
        expect(entry.apiKeyUrl, isNull, reason: entry.id);
      }
    });

    test('byId round-trips every entry', () {
      for (final entry in ProviderCatalog.all) {
        expect(ProviderCatalog.byId(entry.id)?.id, entry.id);
      }
      expect(ProviderCatalog.byId('tidak-ada'), isNull);
    });

    test('byCategory partitions the catalog', () {
      final total = ProviderCategory.values
          .map((c) => ProviderCatalog.byCategory(c).length)
          .reduce((a, b) => a + b);
      expect(total, ProviderCatalog.all.length);
    });
  });

  group('OAuth section', () {
    test('has at least one selectable (non-custom) preset', () {
      final selectable = OAuthProviderPresets.all
          .where((p) => !p.isCustom)
          .toList();
      expect(selectable, isNotEmpty);
    });
  });
}
