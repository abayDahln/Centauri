import 'package:centauri/features/provider_config/presentation/widgets/model_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  String label = 'cbai/glm-5.2',
  String name = 'GLM-5.2',
  bool selected = false,
  VoidCallback? onTap,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: ModelCard(
          label: label,
          name: name,
          selected: selected,
          onTap: onTap ?? () {},
        ),
      ),
    ),
  ),
);

void main() {
  group('ModelCard', () {
    testWidgets('menampilkan label alias/id + nama ramah', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.text('cbai/glm-5.2'), findsOneWidget);
      expect(find.text('GLM-5.2'), findsOneWidget);
    });

    testWidgets('tap kartu memanggil onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(onTap: () => tapped++));

      await tester.tap(find.byType(ModelCard));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });

    testWidgets('ikon salin tersedia dan menampilkan konfirmasi', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(find.text('Disalin: cbai/glm-5.2'), findsOneWidget);
    });

    testWidgets('menampilkan label panjang tanpa error layout', (tester) async {
      await tester.pumpWidget(
        _host(
          label: 'cl/anthropic/claude-opus-4.7',
          name: 'Claude Opus 4.7',
        ),
      );

      expect(find.text('cl/anthropic/claude-opus-4.7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
