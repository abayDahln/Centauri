# Centauri

**AI-Powered UI & Prototype Builder**

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-4CAF50)]()

> Turn a prompt into a fully responsive, multi-page HTML prototype — then refine, export, and hand off to code or Figma.

---

## Tentang Proyek

**Centauri** adalah aplikasi lintas-platform (Android & Windows) berbasis Flutter untuk membuat **UI dan prototipe web** dari instruksi teks (prompt). AI menghasilkan satu atau lebih **file HTML self-contained** — HTML, CSS, dan JavaScript tergabung dalam satu file — yang saling terhubung lewat link antar-halaman dan bisa langsung dibuka di browser.

Berbeda dari tool kanvas desain, Centauri tidak memakai papan board berkoordinat. Fokusnya adalah **membangun UI & prototipe nyata**: setiap halaman dirender apa adanya di WebView (fluid & responsif ke semua ukuran layar, dari small phone hingga desktop/ultrawide), tanpa toggle device manual.

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
- MCP Server: server MCP embedded (HTTP JSON-RPC di `127.0.0.1:8765`) agar agent eksternal bisa membaca struktur halaman dan memutasi node.

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
| v1.0.0 | Rilis stabil (Android & Windows) dengan optimasi performa WebView |
| v1.1.0 | Auto-layout Figma & import balik dari Figma |

## Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT.
