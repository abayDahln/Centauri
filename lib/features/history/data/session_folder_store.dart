import 'dart:convert';
import 'dart:io';

import '../domain/project.dart';

/// Versi skema manifest sesi. v1: proyek tersimpan sebagai folder.
const int kSessionManifestSchemaVersion = 1;

/// Nama berkas metadata sesi di dalam foldernya.
const String kSessionManifestName = 'manifest.json';

/// Penyimpanan sesi berbasis folder (konsep "satu folder per sesi" ala VS
/// Code): sebuah folder berisi `manifest.json` + satu file HTML self-contained
/// per halaman. Folder adalah sumber kebenaran untuk konten halaman; manifest
/// hanya metadata.
///
/// Config tetap di sini tidak: Hive hanya menyimpan pointer project aktif dan
/// sumber data untuk migrasi proyek lama.
class SessionFolderStore {
  /// Folder root semua sesi. Dipilih saat init aplikasi — Windows:
  /// `%LOCALAPPDATA%\Centauri\sessions`, platform lain memakai directory
  /// pendukung aplikasi.
  SessionFolderStore(this.root);

  final Directory root;

  /// Folder satu sesi: `<root>/<projectId>`.
  Directory folderFor(String projectId) =>
      Directory(_join(root.path, projectId));

  /// Nama file untuk satu halaman. Minimal: slug kepemilikan identitas (lihat
  /// `page_slug.dart`); sanitasi kasus janggal diuji di task berikutnya.
  String fileNameFor(ProjectPage page) => page.slug;

  /// Tulis sesi utuh ke folder: `manifest.json` + satu file HTML per halaman.
  ///
  /// Idempoten: selalu menimpa (ini operasi simpan sejati). Nama file disanitasi
  /// agar aman di Windows dan dibuat unik `case-insensitive` di dalam sesi —
  /// dua halaman dengan slug sama tidak boleh saling menimpa filenya
  /// (`ProjectPage.slug` tidak diubah; identitas tetap di slug).
  void save(Project project) {
    final dir = folderFor(project.id);
    dir.createSync(recursive: true);

    final used = <String>{};
    final pageMeta = <Map<String, String>>[];
    for (final page in project.pages) {
      final file = _uniqueFile(_safeFileName(fileNameFor(page)), used);
      pageMeta.add({
        'id': page.id,
        'name': page.name,
        'slug': page.slug,
        'file': file,
      });
    }

    final manifest = <String, Object?>{
      'schemaVersion': kSessionManifestSchemaVersion,
      'id': project.id,
      'title': project.title,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'activePageId': project.activePageId,
      'pages': pageMeta,
      'messages': project.messages.map((m) => m.toJson()).toList(),
    };
    File(_join(dir.path, kSessionManifestName))
        .writeAsStringSync(jsonEncode(manifest), flush: true);

    // Konten halaman ditulis per file — manifest TIDAK membawa HTML.
    for (var i = 0; i < pageMeta.length; i++) {
      File(_join(dir.path, pageMeta[i]['file']!))
          .writeAsStringSync(project.pages[i].html, flush: true);
    }
  }

  /// Sanitasi nama file untuk Windows: buang karakter dilarang, beri awalan
  /// `_` untuk nama reserved device (mis. `con.html`, `nul.html`).
  static String _safeFileName(String slug) {
    var name = slug.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '-').trim();
    if (name.isEmpty) name = 'page.html';
    final lower = name.toLowerCase();
    final stem = lower.endsWith('.html')
        ? lower.substring(0, lower.length - 5)
        : lower;
    if (_reservedNames.contains(stem)) return '_$name';
    // Filenames lowercase: slugs are domain-identities that are already
    // lowercase (`page_slug.dart`), and Windows is case-insensitive anyway.
    return lower;
  }

  static const Set<String> _reservedNames = {
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
  };

  /// Lengkapi [name] dengan akhiran `-2`, `-3`, ... agar unik `case-insensitive`
  /// terhadap [used] (nama file Windows pun case-insensitive).
  static String _uniqueFile(String name, Set<String> used) {
    if (used.add(name.toLowerCase())) return name;
    final dot = name.lastIndexOf('.');
    final stem = dot <= 0 ? name : name.substring(0, dot);
    final ext = dot <= 0 ? '' : name.substring(dot);
    var i = 2;
    while (true) {
      final candidate = '$stem-$i$ext';
      if (used.add(candidate.toLowerCase())) return candidate;
      i++;
    }
  }

  static String _join(String a, String b) => '$a${Platform.pathSeparator}$b';
}
