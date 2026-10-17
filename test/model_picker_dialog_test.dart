import 'package:centauri/features/provider_config/presentation/widgets/model_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required void Function(ModelPickerResult?) onResult,
    String? catalogId,
    String selectedModel = '',
    List<String> customModels = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showModelPickerDialog(
                  context,
                  catalogId: catalogId,
                  selectedModel: selectedModel,
                  customModels: customModels,
                );
                onResult(result);
              },
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan saran model provider', (tester) async {
    await open(tester, onResult: (_) {}, catalogId: 'groq');

    expect(find.text('Pilih Model'), findsOneWidget);
    expect(find.text('Llama 3.3 70B'), findsOneWidget);
  });

  testWidgets('memilih saran mengembalikan id polos', (tester) async {
    ModelPickerResult? picked;
    await open(tester, onResult: (r) => picked = r, catalogId: 'groq');

    await tester.tap(find.text('Llama 3.3 70B'));
    await tester.pumpAndSettle();

    expect(picked?.modelId, 'llama-3.3-70b-versatile');
  });

  testWidgets('Tambah Model mengembalikan id kustom', (tester) async {
    ModelPickerResult? picked;
    await open(tester, onResult: (r) => picked = r, catalogId: 'groq');

    await tester.tap(find.text('Tambah Model'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'mixtral-8x7b');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(picked?.modelId, 'mixtral-8x7b');
    expect(picked?.customModels, contains('mixtral-8x7b'));
  });

  testWidgets('provider custom tanpa saran tetap bisa tambah model', (
    tester,
  ) async {
    ModelPickerResult? picked;
    await open(tester, onResult: (r) => picked = r, catalogId: 'custom-api');

    expect(find.text('Tambah Model'), findsOneWidget);
    await tester.tap(find.text('Tambah Model'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'gpt-4o');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(picked?.modelId, 'gpt-4o');
  });

  testWidgets('menampilkan model kustom yang sudah ada', (tester) async {
    await open(
      tester,
      onResult: (_) {},
      catalogId: 'custom-api',
      customModels: const ['my-model'],
      selectedModel: 'my-model',
    );

    expect(find.text('my-model'), findsOneWidget);
  });

  testWidgets('model kustom provider template tampil sebagai id polos', (
    tester,
  ) async {
    // Tanpa prefix alias: yang tampil harus sama dengan id yang dikirim ke API.
    // Id di bawah sengaja tidak ada di saran OpenRouter, jadi hanya kartu
    // kustom yang muncul.
    await open(
      tester,
      onResult: (_) {},
      catalogId: 'openrouter',
      customModels: const ['openai/gpt-4o-mini'],
      selectedModel: 'openai/gpt-4o-mini',
    );

    expect(find.text('openai/gpt-4o-mini'), findsOneWidget);
    expect(find.text('openrouter/openai/gpt-4o-mini'), findsNothing);
  });
}
