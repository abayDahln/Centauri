# Centauri: Web Installer

Halaman unduh statis untuk Centauri. Dibuat dengan **React + Vite (JSX)**,
tanpa backend. Halaman ini hanya menampilkan informasi rilis dan tautan unduhan;
proses build, release, dan deploy tetap manual.

## Menjalankan

Prasyarat: Node.js `^20.19.0` atau `>=22.12.0` (Vite 8) dan npm.

```bash
cd web_installer
npm install
npm run dev
```

Vite berjalan di `http://localhost:5173`.

## Build

```bash
npm run build
npm run preview
```

Hasil build ada di `web_installer/dist/`. Folder ini siap diunggah ke static
hosting apa pun (GitHub Pages, Netlify, Cloudflare Pages, Vercel, atau server
sendiri).

`vite.config.js` memakai `base: "./"`, jadi hasil build tetap jalan di root
domain maupun di subpath seperti `https://example.com/Centauri/`.

## Bahasa

Halaman ini mendukung 12 bahasa yang sama dengan aplikasi: Inggris (default),
Indonesia, Mandarin Sederhana, Jepang, Korea, Rusia, Jerman, Arab, Prancis,
Portugis, Thai, dan Filipina.

- `src/i18n/languages.js` berisi daftar bahasa: `code`, `nativeName`, `englishName`,
  dan `dir`. Arab memakai `dir: "rtl"`, sisanya `"ltr"`.
- `src/i18n/translations.js`: kamus teks per bahasa. `en` adalah template dan
  sumber kebenaran untuk daftar kunci; bahasa lain boleh belum lengkap dan akan
  memakai teks Inggris sebagai fallback.
- `src/i18n/LanguageProvider.jsx`: menyediakan `t()`, menyimpan pilihan di
  `localStorage` (`centauri-language`), lalu mengatur `<html lang>`,
  `<html dir>`, judul tab, dan meta deskripsi.

Tombol globe di header membuka daftar bahasa; nama asli ditampilkan bersama nama
Inggris. Untuk menambah bahasa, tambahkan satu entri di `languages.js` dan satu
kamus di `translations.js` dengan kunci yang sama seperti `en`.

Teks bertanda `{accent}` di judul hero dan `{brand}` di judul unduhan diubah
menjadi elemen bergaya oleh `src/components/RichText.jsx`.

## Mengatur rilis

Semua data rilis ada di **`src/config.js`**:

- `version`: versi yang ditampilkan dan dipakai di nama file.
- `releasedAt`: tanggal rilis dalam format ISO `YYYY-MM-DD`. Tanggal ditampilkan
  lewat `Intl.DateTimeFormat` sesuai bahasa yang dipilih.
- `highlights`: objek poin "apa yang baru" per kode bahasa. Hanya `en` yang
  wajib; bahasa lain otomatis memakai teks Inggris kalau belum diterjemahkan.
- `downloads.windows` dan `downloads.android`: nama file, ukuran, requirement,
  dan URL unduhan.

Kartu unduhan memakai ukuran perkiraan: Windows `~30 MB`, Android `± 72 MB`.
Perbarui angka itu setelah build installer yang baru. Halaman hanya menampilkan
Windows dan Android, bukan iOS atau Linux.

Nama file mengikuti artifact workflow:

```text
Centauri-<versi>.apk
Centauri-Setup-<versi>.exe
```

Kalau `url` dikosongkan, tombol unduh membuka halaman GitHub Releases. Setelah
asset diunggah, isi `url` dengan tautan langsung, misalnya:

```js
url: "https://github.com/abayDahln/Centauri/releases/download/v1.0.0/Centauri-Setup-1.0.0.exe",
```

Setelah mengubah `src/config.js`, jalankan `npm run build` lagi.

## Deploy manual

1. Jalankan `npm run build`.
2. Unggah isi `dist/` ke hosting statis.
3. Untuk GitHub Pages, arahkan Pages ke branch/folder yang berisi hasil build
   (misalnya branch `gh-pages`).

Tidak ada workflow CI/CD untuk halaman ini. Release dan deploy dilakukan manual.

## Struktur

```text
web_installer/
├── public/favicon.png
├── src/
│   ├── assets/          # logo + font lokal
│   ├── components/      # Nav, Hero, ProductPreview, Features, HowItWorks,
│   │                    # Install, Release, FAQ, Footer, LanguageMenu, RichText
│   ├── i18n/
│   │   ├── languages.js      # 12 bahasa + arah teks
│   │   ├── translations.js   # kamus per bahasa
│   │   └── LanguageProvider.jsx
│   ├── App.jsx
│   ├── config.js        # data rilis (edit di sini)
│   ├── main.jsx
│   └── styles.css
├── index.html
├── package.json
└── vite.config.js
```

## Catatan

- Halaman ini tidak memanggil API apa pun dan tidak menyimpan data pengguna.
  Hanya preferensi tema dan bahasa yang disimpan di `localStorage`.
- Font Inter, Plus Jakarta Sans, dan JetBrains Mono disalin dari `assets/fonts/`
  di repo utama (OFL). Logo disalin dari `assets/logo/`.
- Tema gelap adalah default; tombol di header bisa mengganti ke tema terang.
  Preferensi disimpan di `localStorage` dengan key `centauri-theme`.
- Bahasa Inggris adalah default; pilihan bahasa disimpan dengan key
  `centauri-language`. Arab membalik halaman ke RTL, sedangkan mockup pratinjau
  produk tetap Inggris dan `dir="ltr"`.
- `dist/` dan `node_modules/` tidak ikut di-commit.
