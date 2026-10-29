import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backend palsu untuk `flutter_secure_storage` di test unit.
///
/// Plugin aslinya butuh native storage (Android Keystore / Windows DPAPI) yang
/// tidak tersedia di test, jadi channel method-nya dijawab oleh peta di memori.
/// Dipasang lewat [install] dan dilepas lewat [uninstall].
class FakeSecureStorageChannel {
  static const MethodChannel _channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  /// Isi penyimpanan; dipakai test untuk memeriksa key yang benar-benar
  /// ditulis (mis. memastikan token tidak bocor ke tempat lain).
  final Map<String, String> data = {};

  void install() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  Future<Object?> _handle(MethodCall call) async {
    final args = (call.arguments as Map).cast<String, Object?>();
    final key = args['key'] as String?;
    switch (call.method) {
      case 'read':
        return data[key];
      case 'write':
        data[key!] = args['value'] as String;
        return null;
      case 'delete':
        data.remove(key);
        return null;
      case 'readAll':
        return data;
      case 'deleteAll':
        data.clear();
        return null;
      case 'containsKey':
        return data.containsKey(key);
    }
    return null;
  }
}
