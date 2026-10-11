import 'package:hive_flutter/hive_flutter.dart';

import '../utils/app_constants.dart';

/// Local database (Hive) untuk metadata provider dan riwayat proyek (FR-06).
/// Nilai disimpan sebagai JSON string agar tidak perlu Hive type adapter.
class LocalStorageService {
  LocalStorageService._internal();
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  late Box<String> _providersBox;
  late Box<String> _metaBox;

  Future<void> init() async {
    _providersBox = await Hive.openBox<String>(AppConstants.providersBoxName);
    _metaBox = await Hive.openBox<String>(AppConstants.metaBoxName);
  }

  List<String> readAllProvidersJson() => _providersBox.values.toList();

  void writeProviderJson(String id, String json) => _providersBox.put(id, json);

  Future<void> deleteProviderJson(String id) => _providersBox.delete(id);

  String? get activeProviderId => _metaBox.get(AppConstants.activeProviderIdKey);

  Future<void> setActiveProviderId(String id) =>
      _metaBox.put(AppConstants.activeProviderIdKey, id);
}
