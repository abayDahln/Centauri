# Centauri

**AI-Powered UI & Prototype Builder**

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-4CAF50)]()

> From a prompt to finished **UI designs and clickable prototypes** — fluid-responsive HTML pages you can refine in chat, export, and hand off to code or Figma.

---

## Tentang Proyek

**Centauri** adalah aplikasi lintas-platform (Android & Windows) berbasis Flutter untuk **membuat UI design dan prototipe** dari instruksi teks (prompt). AI menghasilkan satu atau lebih **file HTML self-contained** — HTML, CSS, dan JavaScript tergabung dalam satu file — yang saling terhubung lewat link antar-halaman dan bisa langsung dibuka di browser.

Fokus aplikasi ini murni **desain & prototipe**, bukan code editor dan bukan papan kanvas: setiap prompt menghasilkan halaman UI nyata yang dirender apa adanya di WebView (fluid & responsif dari small phone hingga ultrawide, tanpa toggle device), setiap iterasi dilakukan lewat percakapan, dan hasilnya bisa diekspor atau dibaca agent luar lewat MCP. Proyek disimpan lokal sebagai **satu folder per sesi** (`manifest.json` + satu file HTML per halaman) sehingga desain, chat, dan file hasilnya selalu sinkron.

Berbeda dari tool kanvas desain, Centauri tidak memakai papan board berkoordinat. Halaman adalah artefaknya; link antar-halaman adalah navigasinya.

Nilai utama Centauri adalah **Provider Agnostic (BYOK - Bring Your Own Key)**. Pengguna bebas memakai OpenAI, Gemini, Anthropic, Groq, hingga Ollama lokal. Semua data, API Key, dan riwayat proyek disimpan **Local-First** demi privasi dan keamanan.

## Fitur Utama

**Inti & Fleksibilitas**

- BYOK: kelola Custom API Gateway sendiri (endpoint standar OpenAI, Ollama, Groq, proxy pribadi).
- Local-First: API Key, konfigurasi, dan riwayat proyek tersimpan terenkripsi di perangkat.

**Halaman & Preview**

- Multi-page Prototype: satu blok HTML = satu halaman. AI menentukan jumlah halaman sesuai permintaan; tiap halaman punya nama file (`slug`) unik.
- Interkoneksi Halaman: AI menulis link `<a href="pricing.html">` sungguhan antar-halaman; app meng-intersep klik itu lalu memuat halaman tujuan langsung di preview, tanpa reload WebView. Tersedia juga page switcher internal.
- Fluid Responsive Preview: WebView mengisi penuh area kerja dan wajib responsif ke semua layout (small/medium phone, tablet, desktop, ultrawide) — tanpa lebar tetap, tanpa toggle device.
- Node Selection & Inline Edit: klik elemen di preview untuk memilihnya (bbox + computed style dikirim ke AI), lalu minta revisi; AI menargetkan elemen terpilih.

**Iterasi & Ekspor**

- Iterative Refinement Chat: revisi UI secara bertahap lewat percakapan (halaman yang sama di-generate ulang berdasarkan slug, link tetap stabil).
- Design / Dev Mode: beralih antara preview penuh dan split view dengan code panel read-only (nomor baris + syntax highlight) ala VS Code.
- Code Exporter: ekspor HTML self-contained (seluruh CSS di `<style>`, JS vanilla di `<script>`, tanpa CDN/framework, jalan offline). Tersedia konversi opsional ke React (JSX), Flutter Widget, dan Tailwind.
- Image/Vector/Document Export: simpan halaman aktif sebagai PNG, SVG, atau PDF.
- Export to Figma: hasilkan *payload* JSON yang dibaca plugin companion (`figma-plugin/`) untuk merekonstruksi frame/layer yang bisa diedit di Figma.
- MCP Server (Desktop): server MCP embedded di `127.0.0.1:8765` dengan 6 tool **hemat token** — `list_sessions` (metadata saja), `get_session` (chat ter-paginate + indeks halaman), `get_page_html`, `write_page` / `delete_page` (buat/ubah/hapus design di sesi mana pun), dan `post_to_chat` (agent mengirim penjelasan ke chat). Semua perubahan **langsung tampil** di app (WebView render ulang, history dan chat naik) lewat sinkronisasi state + SSE, tanpa refresh. Dokumentasi lengkap & setup per CLI: [`docs/mcp_server.md`](docs/mcp_server.md).

**Sesi & Penyimpanan**

- Satu folder per sesi di perangkat (`%LOCALAPPDATA%\Centauri\sessions`): `manifest.json` (judul, chat, daftar halaman) + satu file HTML per design — folder adalah sumber kebenaran, siap disalin atau di-commit.
- Riwayat sesi: daftar, cari, buka ulang, ganti judul, hapus; sesi aktif dipulihkan otomatis saat app dibuka.
- Impor/ekspor proyek file `.mydesign` untuk berpindah perangkat atau berbagi prototipe.

**Antarmuka Aplikasi**

- Tema Light / Dark / ikuti sistem dengan aksen primary & secondary pilihan (8 preset, memenuhi kontras WCAG ≥ 4.5:1).
- Layout responsif mobile–desktop, toast notifikasi terposisis, dan pesan error berkode yang dilokalkan.

**Bahasa**

- 12 bahasa antarmuka: Inggris (default), Indonesia, Mandarin Sederhana, Jepang, Korea, Rusia, Jerman, Arab, Prancis, Portugis, Thai, dan Filipina. Ganti lewat tombol globe di top bar; pilihan disimpan di perangkat.
- Chat dengan AI tidak terikat bahasa UI: Alpha menjawab dalam bahasa pesan yang dikirim pengguna.
- Arab didukung penuh termasuk tata letak kanan-ke-kiri (RTL).

## Tech Stack

| Kategori | Teknologi |
| :--- | :--- |
| Framework | Flutter 3.x (Dart 3.x) |
| State Management | Flutter Riverpod |
| Networking | Dio (Custom Interceptors) |
| Local Storage | Hive (Database), `flutter_secure_storage` (API Keys) |
| Web Rendering | `webview_flutter` (Android), `webview_windows` (Desktop) |
| MCP | Embedded HTTP JSON-RPC server + SSE |
| UI Theme | VS Code Dark Modern (Segoe UI / Consolas) |
| Bahasa (i18n) | `flutter_localizations` + ARB per bahasa (`lib/l10n/`) |
| Architecture | Feature-First Clean Architecture |

## Arsitektur & Alur Kerja

Centauri mengikuti Clean Architecture dengan pemisahan ketat antara UI, Domain, dan Data layer. Alur kerja utama:

1. **Konfigurasi:** pengguna mengatur Custom Endpoint (Base URL, API Key, Model).
2. **Input:** pengguna menulis prompt (boleh multi-halaman, mis. "buatkan login, home, dan profile").
3. **Processing:** Prompt Engineering Layer menambahkan instruksi wajib: fluid/responsif, `<meta name="centauri-page">`, dan link antar-halaman.
4. **Eksekusi:** Dynamic HTTP Client (Dio) mengirim request ke provider AI yang dipilih.
5. **Rendering:** respons AI di-parse menjadi N halaman; DOM tiap halaman di-stamp id untuk seleksi lalu dirender di WebView.
6. **Iterasi:** revisi via Chat, pindah halaman via link/switcher.
7. **Ekspor:** kode (HTML/React/Flutter/Tailwind), gambar (PNG/SVG/PDF), atau payload Figma.
8. **Kolaborasi agent (Desktop):** AI agent luar tersambung ke MCP server untuk membaca sesi, membuat/mengubah/menghapus halaman design, dan menulis penjelasan ke chat — hasilnya tampil live di app.

## Dokumentasi

| Berkas | Isi |
| :--- | :--- |
| [`docs/mcp_server.md`](docs/mcp_server.md) | Protokol MCP, 6 tool, contoh curl, setup per CLI (Qoder, Claude Code, Codex, OpenCode, Antigravity, Cline) |
| [`docs/design_system.md`](docs/design_system.md) | Token warna/tipografi/spacing aplikasi |
| [`docs/feature_map.md`](docs/feature_map.md) | Peta fitur ke modul kode |
| [`docs/project_documentation.md`](docs/project_documentation.md) | Detail arsitektur per layer |
| [`AGENTS.md`](AGENTS.md) | Brief kanonik untuk AI agent yang mengerjakan repo ini |

## Instalasi

Prasyarat:

- Flutter SDK 3.19.0 atau lebih baru
- Android Studio (untuk target Android)
- Visual Studio dengan workload Desktop development with C++ (untuk target Windows)

Langkah menjalankan:

1. Clone repository:
   ```bash
   git clone https://github.com/username/centauri.git
   cd centauri
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi:
   ```bash
   flutter run
   ```

Teks antarmuka tidak ditulis di widget. Semua string ada di `lib/l10n/app_<kode>.arb`
dengan `app_en.arb` sebagai template; `flutter gen-l10n` berjalan otomatis saat
build. Setelah mengubah ARB, jalankan manual bila perlu:

```bash
flutter gen-l10n
```

Menambah bahasa: buat `lib/l10n/app_<kode>.arb` dengan kunci yang sama seperti
`app_en.arb`, daftarkan di `AppLanguage.all`, lalu `flutter gen-l10n`. Tombol
globe hanya menampilkan bahasa yang file ARB-nya ada.

## Konfigurasi BYOK

Karena menggunakan arsitektur BYOK, konfigurasikan provider AI saat pertama kali membuka aplikasi:

1. Buka Settings / Provider Config, lalu klik Add New Provider.
2. Isi Provider Name, Base URL, API Key, dan Model Name (contoh: `gpt-4o`, `llama3`, `mixtral-8x7b`).
3. Klik Test Connection untuk memvalidasi kredensial, lalu Save.

## Plugin Figma

Folder [`figma-plugin/`](figma-plugin/) berisi plugin companion untuk mengimpor desain Centauri ke Figma. Lihat [`figma-plugin/README.md`](figma-plugin/README.md) untuk instalasi dan skema payload.

## Roadmap

| Versi | Target |
| :--- | :--- |
| v0.1.0 | Fondasi proyek, BYOK Manager, preview halaman dasar |
| v0.2.0 | Multi-halaman + interkoneksi link, Iterative Chat, Code Exporter |
| v0.3.0 | Ekspor PNG/SVG/PDF, MCP server, plugin Figma |
| v0.4.0 | Sesi-level MCP (read hemat token + design CRUD + post-to-chat, live sync), 12 bahasa, tema light/dark + aksen custom, layout responsif |
| v1.0.0 | Rilis stabil (Android & Windows) dengan optimasi performa WebView |
| v1.1.0 | Auto-layout Figma & import balik dari Figma |

## Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT.
