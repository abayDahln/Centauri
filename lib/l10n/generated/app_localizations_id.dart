// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Centauri — Kanvas UI/UX AI';

  @override
  String get languageTooltip => 'Bahasa';

  @override
  String get languageDialogTitle => 'Bahasa';

  @override
  String get commonAdd => 'Tambah';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonEdit => 'Ubah';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonActive => 'Aktif';

  @override
  String get commonSetActive => 'Jadikan aktif';

  @override
  String get commonProvider => 'Provider';

  @override
  String get commonBaseUrl => 'Base URL';

  @override
  String get commonApiKey => 'API Key';

  @override
  String get commonModel => 'Model';

  @override
  String get providerListHeading => 'Bring Your Own Key (BYOK)';

  @override
  String get providerListSubtitle =>
      'Semua data tersimpan dan terenkripsi di perangkat Anda.';

  @override
  String get providerListLoadFailed => 'Gagal memuat daftar provider.';

  @override
  String get providerListEmptyTitle => 'Belum ada provider';

  @override
  String get providerListEmptyBody =>
      'Tambahkan provider untuk mulai menggunakan Centauri.';

  @override
  String get providerListAddProvider => 'Tambah provider';

  @override
  String get providerDeleted => 'Provider dihapus';

  @override
  String get providerDetailPickProvider => 'Pilih provider dulu.';

  @override
  String get providerDetailPickModel => 'Pilih model dulu.';

  @override
  String providerDetailSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'Gagal menghapus API Key: $error';
  }

  @override
  String get providerDetailUpdated => 'Provider diperbarui.';

  @override
  String get providerDetailAdded => 'Provider ditambahkan.';

  @override
  String get providerDetailTestOk => 'Koneksi berhasil.';

  @override
  String get providerDetailTitleEdit => 'Ubah provider';

  @override
  String get providerDetailTitleNew => 'Tambah provider';

  @override
  String get providerDetailDeleteTooltip => 'Hapus provider';

  @override
  String get providerDetailFieldName => 'Nama';

  @override
  String get providerDetailNameHint => 'e.g. \"OpenAI Pro\"';

  @override
  String get providerDetailNameRequired => 'Nama wajib diisi.';

  @override
  String get providerDetailPickProviderLabel => 'Pilih provider';

  @override
  String get providerDetailFieldProviderName => 'Nama Provider';

  @override
  String get providerDetailProviderNameHint => 'e.g. \"OpenAI\"';

  @override
  String get providerDetailProviderNameRequired => 'Nama provider wajib diisi.';

  @override
  String get providerDetailPickModelLabel => 'Pilih model';

  @override
  String get providerDetailPickProviderFirst => 'Pilih provider dulu';

  @override
  String get providerDetailTestAction => 'Test';

  @override
  String get providerDetailBaseUrlRequired => 'Base URL wajib diisi.';

  @override
  String get providerDetailBaseUrlInvalid =>
      'Masukkan URL yang valid (contoh: https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'Dari provider';

  @override
  String get providerDetailApiKeyStored =>
      'API Key tersimpan. Reset untuk mengganti.';

  @override
  String get providerDetailApiKeyCleared => 'API Key dihapus saat disimpan.';

  @override
  String get providerDetailApiKeyOptional =>
      'Kosongkan untuk layanan lokal tanpa autentikasi.';

  @override
  String get providerDetailReset => 'Reset';

  @override
  String get providerDeleteTargetFallback => 'provider ini';

  @override
  String get providerDeleteTitle => 'Hapus provider ini?';

  @override
  String providerDeleteBody(String target) {
    return '$target beserta data tersimpan akan dihapus permanen.';
  }

  @override
  String get modelCardDeleteTooltip => 'Hapus model';

  @override
  String get modelCardCopyIdTooltip => 'Salin id model';

  @override
  String modelCardCopied(String model) {
    return 'Disalin: $model';
  }

  @override
  String get modelPickerTitle => 'Pilih Model';

  @override
  String get modelPickerCustom => 'Model kustom';

  @override
  String get modelPickerAddModel => 'Tambah Model';

  @override
  String get modelPickerIdHint => 'e.g. \"gpt-4o\"';

  @override
  String get providerPickerTitle => 'Pilih Provider';

  @override
  String get commonAllPages => 'Semua halaman';

  @override
  String get canvasUntitledProject => 'Prototype baru';

  @override
  String get canvasHideHistory => 'Sembunyikan riwayat';

  @override
  String get canvasShowHistory => 'Tampilkan riwayat';

  @override
  String get canvasHidePreview => 'Sembunyikan pratinjau';

  @override
  String get canvasShowPreview => 'Tampilkan pratinjau';

  @override
  String get canvasUndoTooltip => 'Urungkan (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'Ulangi (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count layar',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'Desain';

  @override
  String get canvasModeCode => 'Kode';

  @override
  String get canvasServiceSettings => 'Pengaturan layanan';

  @override
  String get canvasSelectionOff => 'Matikan seleksi elemen';

  @override
  String get canvasSelectionOn => 'Pilih elemen di kanvas';

  @override
  String get canvasBreadcrumbFallback => 'kanvas';

  @override
  String get canvasStopGenerating => 'Hentikan generate';

  @override
  String get canvasStopAction => 'Hentikan';

  @override
  String get canvasEmptyTitle => 'Belum ada UI';

  @override
  String get canvasEmptyBody => 'Ketik pesan untuk mulai.';

  @override
  String get canvasPrototypeTitle => 'Prototype';

  @override
  String get canvasChatPanelTooltip => 'Panel chat dan riwayat';

  @override
  String get storageFailedTitle => 'Penyimpanan lokal gagal dibuka. ';

  @override
  String get storageFailedBody => 'Tutup Centauri lain lalu coba lagi.';

  @override
  String get previewGenericError => 'Terjadi kesalahan pada pratinjau.';

  @override
  String previewLinkInvalid(String href) {
    return 'Link tidak valid: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'Tidak bisa membuka: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'Halaman tidak ditemukan: $href';
  }

  @override
  String get previewDeleteFailed => 'Gagal menghapus komponen. Coba lagi.';

  @override
  String get previewLoading => 'Memuat…';

  @override
  String get previewNoPagesTitle => 'Belum ada halaman';

  @override
  String get previewNoPagesBody => 'Ketik pesan untuk membuat halaman.';

  @override
  String get previewLoadFailedTitle => 'Pratinjau gagal dimuat';

  @override
  String get previewWebView2Hint =>
      'Jika tetap gagal, instal Microsoft Edge WebView2 Runtime.';

  @override
  String get exportNoPages => 'Belum ada halaman untuk diekspor.';

  @override
  String exportSaved(String path) {
    return 'Disimpan: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Data Figma ($count elemen) disalin.';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Data Figma ($count elemen) tersimpan: $path';
  }

  @override
  String get exportFailed => 'Ekspor gagal. Coba lagi.';

  @override
  String get exportPageTooltip => 'Ekspor halaman';

  @override
  String get exportPageTooltipCompact => 'Ekspor halaman (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (gambar)';

  @override
  String get exportSvg => 'SVG (vektor)';

  @override
  String get exportPdf => 'PDF (dokumen)';

  @override
  String get exportAction => 'Ekspor';

  @override
  String get codePanelCopied => 'HTML disalin.';

  @override
  String get codePanelCopyTooltip => 'Salin HTML';

  @override
  String get codePanelSaveTooltip => 'Simpan sebagai .html';

  @override
  String get codePanelEmpty => 'Belum ada kode.\nBuat UI terlebih dahulu.';

  @override
  String get promptAnalyzeImage => 'Analisa gambar ini.';

  @override
  String promptUnsupportedFormat(String name) {
    return 'Format \"$name\" tidak didukung.';
  }

  @override
  String promptReadFailed(String name) {
    return 'Gagal membaca \"$name\".';
  }

  @override
  String get promptPlaceholder => 'Tulis pesan…';

  @override
  String get promptAttachTooltip => 'Lampirkan berkas';

  @override
  String get promptStopTooltip => 'Hentikan proses';

  @override
  String get promptMentionPagesTooltip => 'Sebut halaman';

  @override
  String get attachmentImageFailed => 'Gambar tidak bisa ditampilkan.';

  @override
  String get attachmentRemoveTooltip => 'Hapus lampiran';

  @override
  String get chatWelcomeTitle => 'Mulai dengan pesan';

  @override
  String get chatWelcomeBody =>
      'Tanya apa saja untuk saran desain, atau minta langsung dibuat.';

  @override
  String get chatTabChat => 'Chat';

  @override
  String get chatTabHistory => 'Riwayat';

  @override
  String get pageRenameTitle => 'Ubah nama halaman';

  @override
  String get pageRenameHint => 'Nama halaman';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(klik dua kali untuk ubah nama)';
  }

  @override
  String get markdownEmpty => '(kosong)';

  @override
  String get windowMinimize => 'Perkecil';

  @override
  String get windowMaximize => 'Perbesar';

  @override
  String get windowRestore => 'Kembalikan';

  @override
  String get windowClose => 'Tutup';

  @override
  String get historyRenameTitle => 'Ganti nama';

  @override
  String get historyRenameHint => 'Nama percakapan';

  @override
  String get historyNewChat => 'Chat baru';

  @override
  String get historySearchHint => 'Cari percakapan';

  @override
  String get historyRecent => 'Terbaru';

  @override
  String get historyRenameTooltip => 'Ganti nama';

  @override
  String get historyEmptySearch => 'Tidak ada percakapan yang cocok.';

  @override
  String get historyEmptyList => 'Belum ada percakapan tersimpan.';

  @override
  String get codeExportTitle => 'Ekspor kode';

  @override
  String codeExportCopied(String format) {
    return 'Kode $format disalin.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count karakter',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'Salin';

  @override
  String get codeExportDownload => 'Unduh';

  @override
  String get codeExportNoticeHtml =>
      'Satu file HTML utuh: CSS dan JS digabung, langsung jalan offline.';

  @override
  String get codeExportNoticeReact =>
      'Konversi perkiraan. Pindahkan isi tag <style> ke file CSS sendiri, lalu periksa sebelum dipakai.';

  @override
  String get codeExportNoticeFlutter =>
      'Konversi perkiraan. Hanya inline style yang diterjemahkan; CSS di tag <style> tidak ikut. Periksa sebelum dipakai.';

  @override
  String get codeExportNoticeTailwind =>
      'Konversi perkiraan. Butuh Tailwind v3.2+; isi tag <style> pindahkan ke file CSS. Periksa sebelum dipakai.';

  @override
  String get codeExportTransformErrorTitle => 'Kode tidak bisa diubah';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Kode dari Alpha tidak bisa diubah ke $format.';
  }

  @override
  String get codeExportUseHtml => 'Pakai HTML';

  @override
  String get codeExportEmptyTitle => 'Belum ada UI untuk diekspor';

  @override
  String get codeExportEmptyBody => 'Buat UI terlebih dahulu.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP hanya berjalan di versi Desktop.';

  @override
  String get mcpRunning => 'Berjalan';

  @override
  String get mcpStopped => 'Berhenti';

  @override
  String get mcpDescription =>
      'Jembatan agar AI agent (Claude Code, Cursor) bisa membaca dan mengubah desain. Perubahan tampil langsung.';

  @override
  String get mcpStarting => 'Menyalakan…';

  @override
  String get mcpStart => 'Nyalakan';

  @override
  String get mcpAutoStartNote =>
      'Server menyala otomatis saat aplikasi dibuka.';

  @override
  String get mcpCopyAddress => 'Salin';

  @override
  String get mcpAddressCopied => 'Alamat disalin.';

  @override
  String get chatProcessing => 'Memproses…';

  @override
  String get chatUiReady => 'UI siap';

  @override
  String get chatViewCode => 'Lihat kode';

  @override
  String get chatHideCode => 'Sembunyikan';

  @override
  String get chatNoMessagesTitle => 'Belum ada percakapan';

  @override
  String get chatNoMessagesBody => 'Ketik pesan untuk memulai.';

  @override
  String get commonGenericError => 'Terjadi kesalahan. Coba lagi.';

  @override
  String get canvasMentionElementFallback => 'Elemen terpilih';

  @override
  String get canvasNoProvider =>
      'Belum ada provider aktif. Tambahkan provider untuk mulai.';

  @override
  String get canvasUntitledPage => 'Tanpa judul';

  @override
  String get canvasGenerationStopped => 'Generasi dihentikan.';

  @override
  String get promptAttachmentLimit => 'Maksimal 6 lampiran per pesan.';

  @override
  String get providerNotFound => 'Provider tidak ditemukan.';

  @override
  String get errorCancelled => 'Dibatalkan.';

  @override
  String get errorApiTimeout =>
      'Koneksi timeout. Periksa alamat layanan atau jaringan.';

  @override
  String get errorApiUnreachable =>
      'Tidak bisa terhubung. Periksa alamat layanan.';

  @override
  String get errorApiUnauthorized =>
      'Kunci akses tidak berlaku atau tidak punya akses.';

  @override
  String get errorApiRateLimited =>
      'Layanan sedang membatasi permintaan. Coba lagi sebentar.';

  @override
  String get errorApiNotFound =>
      'Alamat atau model tidak ditemukan. Periksa keduanya.';

  @override
  String get errorApiRejected => 'Layanan menolak permintaan.';

  @override
  String get errorApiCertificate =>
      'Sertifikat server tidak valid. Periksa alamat layanan.';

  @override
  String get errorApiSendFailed =>
      'Gagal mengirim permintaan. Periksa koneksi dan alamat layanan.';

  @override
  String get errorApiBadResponse =>
      'Balasan tidak sesuai format. Alamat sebaiknya berakhir dengan /v1.';

  @override
  String get errorApiNoChatEndpoint => 'Layanan ini belum punya alamat chat.';

  @override
  String get errorApiModelUnavailable =>
      'Model ini tidak tersedia di layanan ini. Pilih model lain.';

  @override
  String get errorApiConnectionBroken => 'Koneksi terputus. Coba lagi.';

  @override
  String errorApiProviderReported(String detail) {
    return 'Pesan layanan: $detail';
  }

  @override
  String get errorGenerationTimeout =>
      'Generate dihentikan: terlalu lama. Coba lagi.';

  @override
  String get errorExportNotReady => 'Halaman belum siap. Tunggu sebentar.';

  @override
  String get errorExportTimeout => 'Ekspor timeout. Coba lagi.';

  @override
  String get errorExportNoElements => 'Belum ada yang bisa diekspor.';

  @override
  String get errorExportEmptyResult => 'Hasil kosong. Coba lagi.';

  @override
  String get errorExportWriteFailed =>
      'Gagal menyimpan file. Coba lokasi lain.';

  @override
  String get errorImportInvalidFile =>
      'File ini bukan JSON yang valid. Pilih file .mydesign dari Centauri.';

  @override
  String get errorImportNotProject => 'File ini bukan proyek Centauri.';

  @override
  String errorImportNewerVersion(String version) {
    return 'File ini butuh Centauri versi lebih baru ($version). Perbarui aplikasi dulu.';
  }

  @override
  String get errorImportEmpty => 'Proyek di file ini kosong.';

  @override
  String errorImportEmptyFile(String name) {
    return 'File $name kosong.';
  }

  @override
  String get errorImportUnusable => 'File tidak bisa dibaca. Coba file lain.';

  @override
  String errorImportUnusableFile(String name) {
    return 'File $name tidak bisa dibaca. Coba file lain.';
  }

  @override
  String get errorAttachmentEmpty => 'File kosong.';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'File $name kosong.';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'File terlalu besar (maks $maxMb MB).';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'Format tidak didukung. Pakai $formats.';
  }

  @override
  String get errorStorageFailed =>
      'Tidak bisa mengakses kunci di perangkat ini.';

  @override
  String get errorTransformNoCode => 'Halaman ini belum punya kode.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get catalogSectionFreeTier => 'Free Tier';

  @override
  String get catalogSectionApiKey => 'API Key';
}
