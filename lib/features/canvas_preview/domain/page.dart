import 'package:flutter/foundation.dart';

import 'dom_tree.dart';

/// Satu halaman UI hasil generate: satu dokumen HTML self-contained
/// (HTML + CSS + JS dalam satu file).
///
/// [slug] adalah nama file halaman untuk link antar-halaman, mis. `home.html`.
/// Halaman saling terhubung lewat `<a href="home.html">` di dalam HTML; app
/// meng-intersep klik itu lalu memuat halaman yang cocok.
@immutable
class AppPage {
  const AppPage({
    required this.id,
    required this.name,
    required this.slug,
    required this.html,
    this.domTree,
  });

  final String id;

  /// Judul halaman (mis. "Home", "Login").
  final String name;

  /// Nama file untuk link, mis. `home.html` (unik per proyek).
  final String slug;

  /// HTML self-contained halaman ini (sudah di-stamp id untuk seleksi node).
  final String html;

  /// DOM tree halaman ini (untuk layers/seleksi & sinkronisasi MCP).
  final DomTreeResult? domTree;

  AppPage copyWith({
    String? name,
    String? slug,
    String? html,
    DomTreeResult? domTree,
  }) {
    return AppPage(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      html: html ?? this.html,
      domTree: domTree ?? this.domTree,
    );
  }
}
