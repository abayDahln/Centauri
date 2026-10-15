import '../domain/catalog/catalog_selection.dart';
import '../domain/entities/api_provider.dart';

/// Argumen navigasi ke layar detail provider (dikirim lewat `extra` go_router).
///
/// - [draft]: provider yang sudah diisi sebagian (mis. saat mengedit sebelum
///   disimpan) — opsional.
/// - [selection]: pilihan dari katalog (API key / OAuth) — opsional.
class ProviderDetailArgs {
  const ProviderDetailArgs({this.draft, this.selection});

  final ApiProvider? draft;
  final CatalogSelection? selection;
}

/// Argumen navigasi ke layar pemilih model.
class ModelPickerArgs {
  const ModelPickerArgs({required this.provider});

  /// Provider (boleh draft/belum tersimpan) yang baseUrl + kredensialnya
  /// dipakai untuk `GET /models`.
  final ApiProvider provider;
}
