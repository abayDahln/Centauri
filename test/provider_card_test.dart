import 'package:centauri/features/provider_config/domain/catalog/provider_catalog_entry.dart';
import 'package:centauri/features/provider_config/presentation/provider_catalog_view_model.dart';
import 'package:centauri/features/provider_config/presentation/widgets/provider_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _entry = ProviderCatalogEntry(
  id: 'groq-test',
  name: 'Groq Test',
  category: ProviderCategory.apiKey,
  baseUrl: 'https://api.groq.com/openai/v1',
  defaultModel: 'llama-3.3-70b-versatile',
  icon: Icons.speed,
  brandColor: Color(0xFFF55036),
  textIcon: 'GQ',
);

ProviderCardData _card({String name = 'Groq Test'}) => ProviderCardData(
  id: 'groq-test',
  name: name,
  subtitle: 'Ada tier gratis',
  logo: const ProviderLogoData(color: Color(0xFFF55036), textIcon: 'GQ'),
  entry: _entry,
);

Widget _host(ProviderCardData data, {VoidCallback? onTap}) => MaterialApp(
  home: Scaffold(body: ProviderCard(data: data, onTap: onTap ?? () {})),
);

void main() {
  group('ProviderCard', () {
    testWidgets('menampilkan nama dan subtitle', (tester) async {
      await tester.pumpWidget(_host(_card()));

      expect(find.text('Groq Test'), findsOneWidget);
      expect(find.text('Ada tier gratis'), findsOneWidget);
    });

    testWidgets('tap kartu memanggil onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(_card(), onTap: () => tapped++));

      await tester.tap(find.byType(ProviderCard));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });
  });

  group('ProviderCatalogPanel data', () {
    test('setiap kartu view-model bisa dirender ProviderCard', () {
      final data = ProviderCatalogViewModel.allCards().first;
      expect(data.name.trim(), isNotEmpty);
      expect(data.entry.id, isNotEmpty);
    });
  });
}
