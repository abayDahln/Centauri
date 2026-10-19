import 'package:centauri/features/provider_config/presentation/widgets/model_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

Widget _host({
  String label = 'cbai/glm-5.2',
  String name = 'GLM-5.2',
  String modelId = 'glm-5.2',
  bool selected = false,
  VoidCallback? onTap,
}) => testApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: ModelCard(
          label: label,
          name: name,
          modelId: modelId,
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

    testWidgets('ikon salin tersedia dan menampilkan konfirmasi', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(find.text('Disalin: glm-5.2'), findsOneWidget);
    });

    testWidgets('ikon salin menyalin id polos, bukan label tampilan', (
      tester,
    ) async {
      // Label `openrouter/openai/gpt-5.4` hanya hiasan; id yang diterima API
      // adalah `openai/gpt-5.4`. Menyalin label membuat model ditolak (404).
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        _host(
          label: 'openrouter/openai/gpt-5.4',
          name: 'GPT-5.4',
          modelId: 'openai/gpt-5.4',
        ),
      );

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(copied, 'openai/gpt-5.4');
      expect(find.text('Disalin: openai/gpt-5.4'), findsOneWidget);
    });

    testWidgets('menampilkan label panjang tanpa error layout', (tester) async {
      await tester.pumpWidget(
        _host(label: 'cl/anthropic/claude-opus-4.7', name: 'Claude Opus 4.7'),
      );

      expect(find.text('cl/anthropic/claude-opus-4.7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
