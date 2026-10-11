# Centauri

**AI-Powered UI/UX Canvas & Code Generator**

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-4CAF50)]()

> Transform your ideas into interactive UI and production-ready code in seconds. Powered by your favorite AI models.

---

## Tentang Proyek

**Centauri** adalah aplikasi lintas-platform (Android & Windows) berbasis Flutter yang menjembatani desain visual dan penulisan kode. Terinspirasi oleh Google Stitch, Centauri memungkinkan designer, developer, dan maker menghasilkan antarmuka pengguna serta kode siap pakai hanya dari instruksi teks (prompt).

Nilai utama Centauri adalah **Provider Agnostic (BYOK - Bring Your Own Key)**. Pengguna tidak terikat pada satu penyedia layanan cloud dan bebas menggunakan OpenAI, Gemini, Anthropic, Groq, hingga server Ollama lokal. Semua data, API Key, dan riwayat proyek disimpan secara **Local-First** demi privasi dan keamanan.

## Fitur Utama

**Inti & Fleksibilitas**

- BYOK: kelola Custom API Gateway sendiri (endpoint standar OpenAI, Ollama, Groq, proxy pribadi).
- Local-First: API Key, konfigurasi, dan riwayat proyek tersimpan terenkripsi di perangkat.

**Desain & Visualisasi**

- Live Interactive Canvas: render real-time HTML5 & Tailwind CSS di WebView internal.
- Design Token Presets: tetapkan color palette, border radius, dan font family sebelum generasi.
- Responsive Viewport Preview: pratinjau mode Mobile (375px), Tablet (768px), dan Desktop (100%).

**Iterasi & Ekspor**

- Iterative Refinement Chat: revisi UI secara bertahap melalui percakapan.
- Multi-Format Code Exporter: ekspor ke React (JSX), Tailwind CSS, Flutter Widget, atau HTML murni dengan syntax highlighting.

## Tech Stack

| Kategori | Teknologi |
| :--- | :--- |
| Framework | Flutter 3.x (Dart 3.x) |
| State Management | Flutter Riverpod |
| Networking | Dio (Custom Interceptors) |
| Local Storage | Hive (Database), `flutter_secure_storage` (API Keys) |
| Web Rendering | `webview_flutter` (Android), `webview_windows` (Desktop) |
| Architecture | Feature-First Clean Architecture |

## Arsitektur & Alur Kerja

Centauri mengikuti Clean Architecture dengan pemisahan ketat antara UI, Domain, dan Data layer. Alur kerja utama:

1. **Konfigurasi:** pengguna mengatur Custom Endpoint (Base URL, API Key, Model).
2. **Input:** pengguna menulis prompt dan memilih Design Tokens.
3. **Processing:** Prompt Engineering Layer menggabungkan input dengan System Prompt internal.
4. **Eksekusi:** Dynamic HTTP Client (Dio) mengirim request ke provider AI yang dipilih.
5. **Rendering:** respons AI (HTML/Tailwind) di-parse dan di-inject ke Live Canvas.
6. **Ekspor:** iterasi via Chat, lalu ekspor kode ke format yang diinginkan.

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

## Konfigurasi BYOK

Karena menggunakan arsitektur BYOK, konfigurasikan provider AI saat pertama kali membuka aplikasi:

1. Buka Settings / Provider Config, lalu klik Add New Provider.
2. Isi Provider Name, Base URL, API Key, dan Model Name (contoh: `gpt-4o`, `llama3`, `mixtral-8x7b`).
3. Klik Test Connection untuk memvalidasi kredensial, lalu Save.

## Roadmap

| Versi | Target |
| :--- | :--- |
| v0.1.0 | Fondasi proyek, BYOK Manager, dan Live Canvas dasar |
| v0.2.0 | Iterative Chat, Multi-format Code Exporter, dan Responsive Viewport |
| v1.0.0 | Rilis stabil (Android & Windows) dengan optimasi performa WebView |
| v1.1.0 | Import desain dari Figma via Figma API |
| v1.2.0 | Integrasi native Ollama tanpa setup server HTTP manual |

## Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT.
