import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/oauth_token_set.dart';

/// Kegagalan saat mengimpor token lokal (mis. Cursor).
class ImportTokenException implements Exception {
  const ImportTokenException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Membaca token OAuth dari penyimpanan lokal aplikasi lain.
///
/// Implementasi saat ini: **Cursor IDE** — membaca `cursorAuth/accessToken`
/// dari `state.vscdb` (SQLite) di direktori data Cursor.
class CursorTokenImporter {
  const CursorTokenImporter({this.candidatePaths, this.openDatabase});

  /// Path kandidat database (untuk pengujian). Null = deteksi otomatis.
  final List<String>? candidatePaths;

  /// Pembuka database (untuk pengujian). Null = `sqlite3.open` read-only.
  final Database Function(String path)? openDatabase;

  static const List<String> _tokenKeys = [
    'cursorAuth/accessToken',
    'cursorAuth/token',
  ];

  Future<OAuthTokenSet> import() async {
    final dbPath = _findDatabase();
    if (dbPath == null) {
      throw const ImportTokenException(
        'Database Cursor tidak ditemukan. Pastikan Cursor IDE terpasang dan '
        'pernah dijalankan minimal sekali.',
      );
    }

    final Database db;
    try {
      db = (openDatabase ?? _openReadOnly)(dbPath);
    } catch (e) {
      throw ImportTokenException('Tidak dapat membuka database Cursor: $e');
    }

    try {
      final token = _readFirst(db, _tokenKeys);
      if (token == null || token.isEmpty) {
        throw const ImportTokenException(
          'Token Cursor tidak ditemukan. Silakan login di Cursor IDE dulu.',
        );
      }
      return OAuthTokenSet(
        accessToken: token,
        // Cursor tidak mengirim masa berlaku; pakai default panjang.
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    } finally {
      db.dispose();
    }
  }

  static Database _openReadOnly(String path) =>
      sqlite3.open(path, mode: OpenMode.readOnly);

  String? _findDatabase() {
    for (final path in candidatePaths ?? _defaultCandidatePaths()) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  List<String> _defaultCandidatePaths() {
    final env = Platform.environment;
    final appData = env['APPDATA'];
    final localAppData = env['LOCALAPPDATA'];
    final home = env['USERPROFILE'] ?? env['HOME'];
    final paths = <String>[];

    if (Platform.isWindows) {
      if (appData != null) {
        paths.add('$appData\\Cursor\\User\\globalStorage\\state.vscdb');
        paths.add('$appData\\Cursor - Insiders\\User\\globalStorage\\state.vscdb');
      }
      if (localAppData != null) {
        paths.add('$localAppData\\Cursor\\User\\globalStorage\\state.vscdb');
        paths.add(
          '$localAppData\\Programs\\Cursor\\User\\globalStorage\\state.vscdb',
        );
      }
    } else if (Platform.isMacOS && home != null) {
      paths.add(
        '$home/Library/Application Support/Cursor/User/globalStorage/state.vscdb',
      );
      paths.add(
        '$home/Library/Application Support/Cursor - Insiders/User/globalStorage/state.vscdb',
      );
    } else if (home != null) {
      paths.add('$home/.config/Cursor/User/globalStorage/state.vscdb');
      paths.add('$home/.config/cursor/User/globalStorage/state.vscdb');
    }
    return paths;
  }

  String? _readFirst(Database db, List<String> keys) {
    final stmt = db.prepare(
      'SELECT value FROM itemTable WHERE key = ? LIMIT 1',
    );
    try {
      for (final key in keys) {
        final rows = stmt.select([key]);
        if (rows.isEmpty) continue;
        final value = _normalize(rows.first['value']);
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    } finally {
      stmt.dispose();
    }
  }

  /// Nilai bisa tersimpan sebagai string JSON (mis. `"abc"`); buka kutipnya.
  String? _normalize(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString();
    try {
      final parsed = jsonDecode(text);
      if (parsed is String) return parsed;
    } catch (_) {
      // Bukan JSON — pakai apa adanya.
    }
    return text;
  }
}
