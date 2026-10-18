import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../canvas_preview/domain/page_slug.dart';
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

    // Bersihkan sisa file halaman yang dihapus/ganti nama agar folder selalu
    // persis deskripsi manifest (folder ini juga dibuka langsung oleh user).
    final referenced = pageMeta.map((m) => m['file']!.toLowerCase()).toSet();
    for (final entry in dir.listSync()) {
      if (entry is! File) continue;
      final name = _nameOf(entry.path).toLowerCase();
      if (!name.endsWith('.html')) continue;
      if (name == kSessionManifestName) continue;
      if (!referenced.contains(name)) entry.deleteSync();
    }
  }

  /// Muat satu sesi; `null` bila folder tidak ada atau manifest rusak.
  Project? load(String id) {
    final dir = folderFor(id);
    final manifestFile = File(_join(dir.path, kSessionManifestName));
    if (!manifestFile.existsSync()) return null;
    try {
      final json = jsonDecode(manifestFile.readAsStringSync());
      if (json is! Map<String, dynamic>) return null;
      return _projectFromManifest(json, dir);
    } catch (e) {
      // Folder rusak bukan alasan untuk menggagalkan seluruh daftar riwayat.
      debugPrint('[sessions] manifest rusak di ${dir.path}: $e');
      return null;
    }
  }

  /// Muat semua sesi dari root, urut `updatedAt` terbaru dulu. Folder tanpa
  /// berkas `manifest.json` (.tmp, sampah manual) dilewati diam-diam.
  List<Project> loadAll() {
    if (!root.existsSync()) return const [];
    final projects = <Project>[];
    for (final entry in root.listSync()) {
      if (entry is! Directory) continue;
      final project = load(_nameOf(entry.path));
      if (project != null) projects.add(project);
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  /// Bangun [Project] dari manifest: HTML halaman DIBACA dari file (sumber
  /// kebenaran), manifest hanya metadata. File yang hilang → html kosong;
  /// halaman tetap muncul agar pengguna bisa memintanya dibuat ulang.
  static Project _projectFromManifest(
    Map<String, dynamic> json,
    Directory dir,
  ) {
    final pagesJson = (json['pages'] as List<dynamic>? ?? const []);
    final pages = <ProjectPage>[];
    for (final raw in pagesJson) {
      final meta = raw as Map<String, dynamic>;
      final file = meta['file'] as String? ?? '';
      final htmlFile = file.isEmpty ? null : File(_join(dir.path, file));
      pages.add(
        ProjectPage(
          id: meta['id'] as String? ?? 'page',
          name: meta['name'] as String? ?? 'Untitled',
          slug:
              meta['slug'] as String? ??
              slugify(meta['name'] as String? ?? 'page'),
          html: htmlFile != null && htmlFile.existsSync()
              ? htmlFile.readAsStringSync()
              : '',
        ),
      );
    }
    final messages = (json['messages'] as List<dynamic>? ?? const [])
        .map((m) => ProjectMessage.fromJson(m as Map<String, dynamic>))
        .toList();
    return Project(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Percakapan baru',
      messages: messages,
      pages: pages,
      activePageId: json['activePageId'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Segmen nama terakhir dari sebuah path.
  static String _nameOf(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.isEmpty ? path : parts.last;
  }

  /// Hapus folder sesi utuh. Tidak melempar bila folder tidak ada.
  void delete(String projectId) {
    final dir = folderFor(projectId);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
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
