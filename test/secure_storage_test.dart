import 'package:centauri/core/storage/secure_storage_service.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecureStorageException', () {
    test('message is preserved verbatim', () {
      final ex = SecureStorageException('Gagal menyimpan API key.');
      expect(ex.message, 'Gagal menyimpan API key.');
      expect(ex.toString(), 'Gagal menyimpan API key.');
    });
  });

  group('ApiProvider key handling (fix Test Connection saat edit)', () {
    const stored = ApiProvider(
      id: 'p1',
      name: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      model: 'llama3',
      apiKey: 'gsk-stored-secret',
    );

    test('form tanpa key (apiKey null) bisa memakai key tersimpan', () {
      // Form edit mengirim apiKey null bila field dikosongkan.
      const fromForm = ApiProvider(
        id: 'p1',
        name: 'Groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        model: 'llama3',
      );
      expect(fromForm.apiKey, isNull);

      // Fix: lengkapi dengan key tersimpan agar Test Connection berhasil.
      final effective = fromForm.copyWith(apiKey: stored.apiKey);
      expect(effective.apiKey, 'gsk-stored-secret');
      expect(effective.id, 'p1');
      expect(effective.baseUrl, 'https://api.groq.com/openai/v1');
    });

    test('key baru dari form menang atas key tersimpan', () {
      const fromForm = ApiProvider(
        id: 'p1',
        name: 'Groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        model: 'llama3',
        apiKey: 'gsk-new-secret',
      );
      // Logika fix hanya menimpa bila fromForm.apiKey == null.
      final effective = fromForm.apiKey == null
          ? fromForm.copyWith(apiKey: stored.apiKey)
          : fromForm;
      expect(effective.apiKey, 'gsk-new-secret');
    });

    test('toJson tetap tidak pernah memuat apiKey', () {
      final json = stored.toJson();
      expect(json.containsKey('apiKey'), isFalse);
    });
  });
}
