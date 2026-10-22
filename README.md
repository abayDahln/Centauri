<p align="center">
  <img src="assets/logo/tile.png" width="112" alt="Logo Centauri">
</p>

# Centauri

**AI-Powered UI & Prototype Builder**

[![CI](https://github.com/abayDahln/Centauri/actions/workflows/ci.yml/badge.svg)](https://github.com/abayDahln/Centauri/actions/workflows/ci.yml)
[![Release installers](https://github.com/abayDahln/Centauri/actions/workflows/release.yml/badge.svg)](https://github.com/abayDahln/Centauri/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.5-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-4CAF50)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> From a prompt to finished **UI designs and clickable prototypes**: fluid-responsive HTML pages you can refine in chat, export, and hand off to code or Figma.

**Versi saat ini:** `1.0.0+1` · Android & Windows · MIT

---

## Tentang Proyek

**Centauri** adalah aplikasi lintas-platform (Android & Windows) berbasis Flutter untuk **membuat UI design dan prototipe** dari instruksi teks (prompt). AI menghasilkan satu atau lebih **file HTML self-contained** (HTML, CSS, dan JavaScript tergabung dalam satu file) yang saling terhubung lewat link antar-halaman dan bisa langsung dibuka di browser.

Fokus aplikasi ini murni **desain & prototipe**, bukan code editor dan bukan papan kanvas: setiap prompt menghasilkan halaman UI nyata yang dirender apa adanya di WebView (fluid & responsif dari small phone hingga ultrawide, tanpa toggle device), setiap iterasi dilakukan lewat percakapan, dan hasilnya bisa diekspor atau dibaca agent luar lewat MCP. Proyek disimpan lokal sebagai **satu folder per sesi** (`manifest.json` + satu file HTML per halaman) sehingga desain, chat, dan file hasilnya selalu sinkron.

Berbeda dari tool kanvas desain, Centauri tidak memakai papan board berkoordinat. Halaman adalah artefaknya; link antar-halaman adalah navigasinya.

Nilai utama Centauri adalah **Provider Agnostic (BYOK - Bring Your Own Key)**. Pengguna bebas memakai OpenAI, Gemini, Anthropic, Groq, hingga Ollama lokal. Semua data, API Key, dan riwayat proyek disimpan **Local-First** demi privasi dan keamanan.

## Fitur Utama

**Inti & Fleksibilitas**

- BYOK: OpenAI, Gemini, Anthropic, Groq, Ollama, atau gateway OpenAI-compatible sendiri (termasuk proxy).
- Local-First: API Key disimpan di `flutter_secure_storage`; konfigurasi di Hive lokal; sesi dan file desain di folder sesi (lihat **Sesi & Penyimpanan**). Tidak ada data yang dikirim ke server selain request ke provider yang dipilih.

**Halaman & Preview**

- Multi-page Prototype: satu blok HTML = satu halaman. AI menentukan jumlah halaman sesuai permintaan; tiap halaman punya nama file (`slug`) unik.
- Interkoneksi Halaman: AI menulis link `<a href="pricing.html">` sungguhan antar-halaman; app mencegat klik itu lalu memuat halaman tujuan langsung di preview, tanpa reload WebView. Tersedia juga page switcher internal.
- Fluid Responsive Preview: WebView mengisi penuh area kerja dan wajib responsif ke semua layout (small/medium phone, tablet, desktop, ultrawide), tanpa lebar tetap, tanpa toggle device.
- Node Selection & Inline Edit: klik elemen di preview untuk memilihnya (bbox + computed style dikirim ke AI), lalu minta revisi; AI menargetkan elemen terpilih.

**Iterasi & Ekspor**

- Iterative Refinement Chat: revisi UI secara bertahap lewat percakapan (halaman yang sama di-generate ulang berdasarkan slug, link tetap stabil).
- Mode Desain / Kode: beralih antara preview penuh dan split view dengan code panel read-only (nomor baris + syntax highlight).
- Code Exporter: ekspor HTML self-contained (seluruh CSS di `<style>`, JS vanilla di `<script>`, tanpa CDN/framework, jalan offline). Tersedia konversi opsional ke React (JSX), Flutter Widget, dan Tailwind.
- Image/Vector/Document Export: simpan halaman aktif sebagai PNG, SVG, atau PDF.
- Export to Figma: salin **halaman aktif** sebagai SVG ke clipboard, lalu tempel langsung ke board Figma (Ctrl+V) - tiap elemen jadi group, teks jadi text layer, gambar jadi image layer, dan halaman jadi satu frame. Halaman selalu dirender ulang pada lebar desktop (minimal 1440 px) supaya hasilnya rapi. Payload JSON untuk plugin companion (`figma-plugin/`) tetap tersedia lewat menu "Figma (plugin)".
- MCP Server (Desktop): server MCP embedded di `127.0.0.1:8765` (fallback 8766–8774), nama server `centauri-canvas`, dengan 6 tool **hemat token**: `list_sessions` (metadata saja), `get_session` (chat ter-paginate + indeks halaman), `get_page_html`, `write_page` / `delete_page` (buat/ubah/hapus design di sesi mana pun), dan `post_to_chat` (agent mengirim penjelasan ke chat). Semua perubahan **langsung tampil** di app (WebView render ulang, history dan chat naik) lewat sinkronisasi state + SSE, tanpa refresh. Panduan setup per CLI tersedia di dialog MCP aplikasi.

**Sesi & Penyimpanan**

- Satu folder per sesi di perangkat. Windows: `%LOCALAPPDATA%\Centauri\sessions`; Android: folder app support (`path_provider`). Isinya `manifest.json` (judul, chat, daftar halaman) + satu file HTML per design; folder adalah sumber kebenaran, siap disalin atau di-commit.
- Riwayat sesi: daftar, cari, buka ulang, ganti judul, hapus; sesi aktif dipulihkan otomatis saat app dibuka.
- Impor/ekspor proyek file `.mydesign` untuk berpindah perangkat atau berbagi prototipe.

**Antarmuka Aplikasi**

- Tema Terang / Gelap / Sistem dengan aksen primary pilihan (8 preset, memenuhi kontras WCAG ≥ 4.5:1).
- Layout responsif mobile–desktop, toast notifikasi, dan pesan error berkode yang dilokalkan.

**Bahasa**

- 12 bahasa antarmuka: Inggris (default), Indonesia, Mandarin Sederhana, Jepang, Korea, Rusia, Jerman, Arab, Prancis, Portugis, Thai, dan Filipina. Ganti lewat tombol globe di top bar; pilihan disimpan di perangkat.
- Chat dengan AI tidak terikat bahasa UI: Alpha menjawab dalam bahasa Inggris sebagai default, dan meniru bahasa user hanya kalau user jelas menulis dalam bahasa lain.
- Arab didukung penuh termasuk tata letak kanan-ke-kiri (RTL).

## Tech Stack

| Kategori | Teknologi |
| :--- | :--- |
| Framework | Flutter 3.47.7 (Dart 3.13.5) |
| State Management | Flutter Riverpod |
| Networking | Dio (custom interceptor) |
| Local Storage | Hive (database), `flutter_secure_storage` (API Key) |
| Web Rendering | `webview_flutter` (Android), `webview_windows` (Windows) |
| Routing | `go_router` |
| Desktop | `window_manager`, `super_clipboard`, `desktop_drop`, `file_picker` |
| MCP | Embedded HTTP JSON-RPC server + SSE |
| Tema & Tipografi | Terang / Gelap / Sistem + 8 aksen primary (`AppPalette`); Inter / Plus Jakarta Sans / Instrument Sans, JetBrains Mono untuk kode |
| Export | HTML, React (JSX), Flutter Widget, Tailwind, PNG, SVG, PDF, Figma |
| Bahasa (i18n) | `flutter_localizations` + ARB per bahasa (`lib/l10n/`) |
| Architecture | Feature-first Clean Architecture |

## Struktur Proyek

```text
lib/
├── app/            # shell, router, tema, bahasa
├── core/           # primitives, error, storage, utils
├── l10n/           # ARB per bahasa + hasil gen-l10n
├── features/
│   ├── canvas_preview/   # WebView, seleksi node, inline edit
│   ├── code_exporter/    # HTML/React/Flutter/Tailwind, PNG/SVG/PDF, Figma
│   ├── history/          # sesi, riwayat, .mydesign
│   ├── mcp/              # server MCP + bridge
│   ├── prompt_editor/    # prompt, chat, refinement
│   └── provider_config/  # BYOK, model, test koneksi
└── main.dart
```

Halaman unduh statis ada di `web_installer/` (React + Vite), terpisah dari
aplikasi Flutter.

## Arsitektur & Alur Kerja

Centauri mengikuti Clean Architecture dengan pemisahan ketat antara UI, Domain, dan Data layer. Alur kerja utama:

1. **Konfigurasi:** pengguna mengatur provider (Base URL, API Key, Model).
2. **Input:** pengguna menulis prompt (boleh multi-halaman, mis. "buatkan login, home, dan profile").
3. **Processing:** Prompt Engineering Layer menambahkan instruksi wajib: fluid/responsif, `<meta name="centauri-page">`, dan link antar-halaman.
4. **Eksekusi:** Dynamic HTTP Client (Dio) mengirim request ke provider AI yang dipilih.
5. **Rendering:** respons AI di-parse menjadi N halaman; DOM tiap halaman di-stamp id untuk seleksi lalu dirender di WebView.
6. **Iterasi:** revisi via Chat, pindah halaman via link/switcher.
7. **Ekspor:** kode (HTML/React/Flutter/Tailwind), gambar (PNG/SVG/PDF), atau payload Figma.
8. **Kolaborasi agent (Desktop):** AI agent luar tersambung ke MCP server untuk membaca sesi, membuat/mengubah/menghapus halaman design, dan menulis penjelasan ke chat; hasilnya tampil live di app.

## Dokumentasi & Konfigurasi

| Berkas | Isi |
| :--- | :--- |
| [`assets/logo/README.md`](assets/logo/README.md) | Sumber logo, ukuran ikon Android/Windows, aturan adaptive icon |
| [`figma-plugin/README.md`](figma-plugin/README.md) | Plugin Figma: instalasi & skema payload |
| [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | CI: analyze, format, test |
| [`.github/workflows/release.yml`](.github/workflows/release.yml) | Release installers: artifact APK + installer |
| [`windows/installer/centauri.iss`](windows/installer/centauri.iss) | Script Inno Setup |
| [`web_installer/README.md`](web_installer/README.md) | Halaman unduh statis (React + Vite): dev, build, deploy, update rilis |

Panduan setup MCP per CLI (Qoder, Claude Code, Codex, OpenCode, Antigravity, Cline) tersedia di dialog MCP di dalam aplikasi.

## Instalasi

Prasyarat:

- Flutter 3.47.7 (Dart 3.13.5)
- JDK 17 (Android; Gradle 8.14 belum mendukung Java 25)
- Android Studio / Android SDK (target Android)
- Visual Studio 2022 + workload Desktop development with C++ (target Windows)
- Inno Setup 6 (installer Windows)

Langkah menjalankan:

1. Clone repository:
   ```bash
   git clone https://github.com/abayDahln/Centauri.git
   cd Centauri
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Regenerate localizations:
   ```bash
   flutter gen-l10n
   ```
4. Jalankan aplikasi:
   ```bash
   flutter run -d windows      # desktop
   # atau
   flutter run -d <device-id>  # Android
   ```

Perintah pengembangan:

| Perintah | Fungsi |
| :--- | :--- |
| `flutter analyze` | Analisis statis |
| `flutter test` | Unit + widget test |
| `dart format lib test` | Format kode |
| `flutter gen-l10n` | Regenerate `AppLocalizations` |

Teks antarmuka tidak ditulis di widget. Semua string ada di `lib/l10n/app_<kode>.arb`
dengan `app_en.arb` sebagai template; `flutter gen-l10n` berjalan otomatis saat
build.

Menambah bahasa: buat `lib/l10n/app_<kode>.arb` dengan kunci yang sama seperti
`app_en.arb`, daftarkan di `AppLanguage.all` (`lib/app/l10n/app_language.dart`),
lalu `flutter gen-l10n`. Tombol globe hanya menampilkan bahasa yang file ARB-nya ada.

## Konfigurasi BYOK

Karena memakai arsitektur BYOK, konfigurasikan provider AI saat pertama kali membuka aplikasi:

1. Buka halaman provider, lalu pilih **Tambah provider**.
2. Isi **Nama Provider**, **Base URL**, **API Key**, dan **Model** (contoh: `gpt-4o`, `llama3`, `mixtral-8x7b`).
3. Pilih **Test** untuk memvalidasi koneksi, lalu **Simpan**.

Untuk Ollama atau layanan lokal tanpa autentikasi, API Key boleh kosong.

## Plugin Figma

Folder [`figma-plugin/`](figma-plugin/) berisi plugin companion untuk mengimpor desain Centauri ke Figma. Lihat [`figma-plugin/README.md`](figma-plugin/README.md) untuk instalasi dan skema payload. Untuk hasil yang bisa langsung ditempel (tanpa plugin), pakai menu **Ekspor > Figma**: SVG halaman aktif disalin ke clipboard dan Figma mengimpornya sebagai layer yang bisa diedit.

### Catatan hasil tempel ke Figma

- **Font**: teks jadi text layer dengan nama font halaman. Kalau font tidak terpasang di Figma, Figma yang memilih font pengganti - hasilnya bisa terlihat beda dan perlu disetel manual.
- **Bayangan** (`box-shadow`) tidak ikut: Figma mengabaikan filter SVG.
- **Pseudo-element** sederhana (bingkai/lingkaran dekoratif) ikut disintesis jadi shape; sisanya perlu ditambah manual.
- **Lebar**: ekspor Figma merender ulang halaman pada lebar desktop (minimal 1440 px), jadi hasilnya tidak ikut sempit saat pratinjau sedang Split View.

## Build & Rilis

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) menjalankan
`dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`,
dan `flutter test` pada setiap push ke `main` dan pull request.

Rilis dibuat manual. Workflow **Release installers**
([`.github/workflows/release.yml`](.github/workflows/release.yml)) hanya
menghasilkan artifact (tidak membuat GitHub Release): jalankan dari tab Actions
(**Run workflow**) atau push tag `v*`, lalu unduh dari bagian **Artifacts** pada
run tersebut.

- `centauri-android` → `Centauri-<versi>.apk`
- `centauri-windows` → `Centauri-Setup-<versi>.exe`

Membuat installer Windows secara lokal (butuh Inno Setup 6):

```powershell
flutter build windows --release
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" `
  "/DAppVersion=1.0.0" "windows\installer\centauri.iss"
# build\windows\installer\Centauri-Setup-1.0.0.exe
```

Membuat APK secara lokal:

Android membutuhkan JDK 17; Gradle 8.14 belum mendukung Java 25. Arahkan
Flutter ke JDK 17 sekali saja:

```bash
flutter config --jdk-dir="<path JDK 17>"
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Ganti `1.0.0` dengan versi di `pubspec.yaml` (mis. `1.0.0+1` → `1.0.0` untuk nama
installer). Installer Windows bersifat per-user (tanpa UAC), untuk Windows 10+
x64, dan belum ditandatangani, jadi Windows SmartScreen bisa menampilkan peringatan.
APK memakai debug signing: bisa dipasang lewat "install dari sumber tidak
dikenal", tetapi belum layak untuk Play Store.

Sumber dan aturan ikon aplikasi ada di [`assets/logo/README.md`](assets/logo/README.md).

### Halaman unduh

Halaman unduh statis ada di `web_installer/` (React + Vite). Halaman ini tidak
dibangun oleh CI dan tidak termasuk build Flutter.

```bash
cd web_installer
npm install
npm run dev
npm run build
```

Data rilis (versi, tanggal, highlights, dan URL unduhan) ada di
`web_installer/src/config.js`. Tanggal memakai format ISO `YYYY-MM-DD` dan
ditampilkan lewat `Intl.DateTimeFormat`; highlight rilis disimpan per bahasa
dengan Inggris sebagai fallback. Ukuran kartu saat ini `~30 MB` untuk Windows
dan `± 72 MB` untuk Android. Isi `downloads.windows.url` dan
`downloads.android.url` setelah asset diunggah; kalau dibiarkan kosong, tombol
membuka GitHub Releases.

Teks antarmuka ada di `web_installer/src/i18n/translations.js` (12 bahasa,
Inggris sebagai template). Arab membalik halaman ke RTL tanpa mengubah mockup
pratinjau. Deploy manual: jalankan `npm run build`, lalu unggah isi
`web_installer/dist/` ke static hosting. Detail:
[`web_installer/README.md`](web_installer/README.md).

## Roadmap

| Versi | Status | Target |
| :--- | :--- | :--- |
| v0.1.0 | Selesai | Fondasi proyek, BYOK Manager, preview halaman dasar |
| v0.2.0 | Selesai | Multi-halaman + interkoneksi link, Iterative Chat, Code Exporter |
| v0.3.0 | Selesai | Ekspor PNG/SVG/PDF, MCP server, plugin Figma |
| v0.4.0 | Selesai | Sesi-level MCP (read hemat token + design CRUD + post-to-chat, live sync), 12 bahasa, tema terang/gelap + aksen custom, layout responsif |
| v1.0.0 | Saat ini (`1.0.0+1`) | Rilis stabil Android & Windows; optimasi performa WebView |
| v1.1.0 | Berikutnya | Auto-layout Figma & import balik dari Figma |

## Lisensi

MIT. Lihat [`LICENSE`](LICENSE).
