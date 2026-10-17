import 'package:flutter/material.dart';

/// Kategori provider untuk pengelompokan di UI.
///
/// Mengikuti penamaan kategori 9router ("Free Tier" / "API Key") plus "Lokal".
enum ProviderCategory { freeTier, apiKey, local }

extension ProviderCategoryLabel on ProviderCategory {
  String get label => switch (this) {
    ProviderCategory.freeTier => 'Free Tier',
    ProviderCategory.apiKey => 'API Key',
    ProviderCategory.local => 'Lokal',
  };
}

/// Metadata satu provider pada katalog siap-pakai.
///
/// Hanya untuk provider yang endpoint-nya **OpenAI-compatible** (Centauri
/// memanggil `POST {baseUrl}/chat/completions`). Karena itu [baseUrl] harus
/// berupa root (mis. `https://api.groq.com/openai/v1`), bukan endpoint penuh.
///
/// Ikon memakai `const Icons.*` + warna brand + inisial teks agar tidak perlu
/// file asset dan tetap aman untuk tree-shaking ikon Flutter.
class ProviderCatalogEntry {
  const ProviderCatalogEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.baseUrl,
    required this.defaultModel,
    required this.icon,
    required this.brandColor,
    required this.textIcon,
    this.website,
    this.apiKeyUrl,
    this.note,
  });

  final String id;
  final String name;
  final ProviderCategory category;

  /// Root Base URL (tanpa `/chat/completions` atau `/models`).
  final String baseUrl;

  final String defaultModel;
  final IconData icon;
  final Color brandColor;

  /// Inisial 1–2 huruf kapital untuk badge teks.
  final String textIcon;

  final String? website;

  /// Halaman untuk membuat API key. Null untuk provider lokal tanpa key.
  final String? apiKeyUrl;

  /// Catatan singkat (mis. "Lewat endpoint OpenAI-compat").
  final String? note;
}
