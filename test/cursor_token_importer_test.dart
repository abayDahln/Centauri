import 'package:centauri/features/provider_config/data/services/cursor_token_importer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CursorTokenImporter', () {
    test('melempar ImportTokenException bila database tidak ditemukan', () async {
      const importer = CursorTokenImporter(candidatePaths: []);
      await expectLater(
        importer.import(),
        throwsA(
          isA<ImportTokenException>().having(
            (e) => e.message,
            'message',
            contains('Database Cursor tidak ditemukan'),
          ),
        ),
      );
    });
  });
}
