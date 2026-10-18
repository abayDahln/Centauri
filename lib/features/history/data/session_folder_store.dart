import 'dart:io';

import '../domain/project.dart';

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

  static String _join(String a, String b) => '$a${Platform.pathSeparator}$b';
}
