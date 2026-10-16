import 'package:centauri/features/provider_config/domain/catalog/catalog_selection.dart';
import 'package:centauri/features/provider_config/domain/catalog/provider_catalog_entry.dart';
import 'package:centauri/features/provider_config/presentation/provider_catalog_view_model.dart';
import 'package:centauri/features/provider_config/presentation/widgets/provider_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _entry = ProviderCatalogEntry(
  id: 'x',
  name: 'Contoh',
  category: ProviderCategory.apiKey,
  baseUrl: 'https://example.com/v1',
  defaultModel: 'm',
  icon: Icons.circle,
  brandColor: Color(0xFF123456),
  textIcon: 'XX',
);

ProviderCardData _card({
  required ProviderLogoData logo,
  bool isTokenOnly = false,
}) => ProviderCardData(
  id: 'x',
  name: 'Contoh',
  subtitle: 'sub',
  logo: logo,
  selection: const ApiKeySelection(_entry),
  isTokenOnly: isTokenOnly,
);

Widget _host(ProviderCardData data, {VoidCallback? onTap}) => MaterialApp(
  home: Scaffold(body: ProviderCard(data: data, onTap: onTap ?? () {})),
);

void main() {
  testWidgets('menampilkan ikon brand bila brandIcon ada', (tester) async {
    await tester.pumpWidget(
      _host(
        _card(
          logo: const ProviderLogoData(
            brandIcon: Icons.abc,
            color: Color(0xFF123456),
            textIcon: 'AB',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.abc), findsOneWidget);
    expect(find.text('AB'), findsNothing);
  });

  testWidgets('menampilkan inisial teks bila brandIcon null', (tester) async {
    await tester.pumpWidget(
      _host(
        _card(
          logo: const ProviderLogoData(color: Color(0xFF123456), textIcon: 'ZZ'),
        ),
      ),
    );

    expect(find.text('ZZ'), findsOneWidget);
  });

  testWidgets('onTap terpanggil saat kartu ditekan', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        _card(
          logo: const ProviderLogoData(color: Color(0xFF123456), textIcon: 'ZZ'),
        ),
        onTap: () => tapped = true,
      ),
    );

    await tester.tap(find.byType(ProviderCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('menampilkan chip "token" untuk provider token-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _card(
          logo: const ProviderLogoData(color: Color(0xFF123456), textIcon: 'ZZ'),
          isTokenOnly: true,
        ),
      ),
    );

    expect(find.text('token'), findsOneWidget);
  });

  testWidgets('data dari katalog view-model bisa dirender', (tester) async {
    final data = ProviderCatalogViewModel.allCards().first;
    await tester.pumpWidget(_host(data));
    expect(find.text(data.name), findsOneWidget);
  });
}
