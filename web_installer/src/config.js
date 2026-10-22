// Konfigurasi situs dan rilis.
//
// Setiap kali merilis versi baru, cukup ubah `version`, `releasedAt`, dan isi
// `url` di bagian downloads. Nama file mengikuti artifact workflow:
//   Centauri-<versi>.apk
//   Centauri-Setup-<versi>.exe
//
// `releasedAt` memakai format ISO (YYYY-MM-DD); tanggal ditampilkan lewat
// Intl.DateTimeFormat sesuai bahasa yang dipilih.
//
// `highlights` adalah objek per kode bahasa. Hanya `en` yang wajib; bahasa lain
// otomatis memakai teks Inggris kalau belum diterjemahkan.
//
// Kalau `url` dibiarkan kosong, tombol unduh membuka halaman GitHub Releases.
// Isi dengan URL asset, misalnya:
//   https://github.com/abayDahln/Centauri/releases/download/v1.0.0/Centauri-Setup-1.0.0.exe
export const site = {
  name: "Centauri",
  tagline: "AI-Powered UI & Prototype Builder",
  github: "https://github.com/abayDahln/Centauri",
  releases: "https://github.com/abayDahln/Centauri/releases",
  license: "https://github.com/abayDahln/Centauri/blob/main/LICENSE",
};

const version = "1.0.0";

export const release = {
  version,
  releasedAt: "2026-10-21",
  notesUrl: site.releases,
  highlights: {
    en: [
      "First release for Android and Windows.",
      "MCP server with 6 tools for external agents.",
      "12 UI languages, including Arabic (RTL).",
      "Export to HTML, React, Flutter, Tailwind, PNG, SVG, PDF, and Figma.",
    ],
    id: [
      "Rilis pertama untuk Android dan Windows.",
      "MCP server dengan 6 tool untuk agent luar.",
      "12 bahasa antarmuka, termasuk Arab (RTL).",
      "Ekspor HTML, React, Flutter, Tailwind, PNG, SVG, PDF, dan Figma.",
    ],
    zh: [
      "首个支持 Android 和 Windows 的版本。",
      "面向外部 Agent 的 MCP 服务器，提供 6 个工具。",
      "12 种界面语言，包括阿拉伯语（RTL）。",
      "支持导出 HTML、React、Flutter、Tailwind、PNG、SVG、PDF 和 Figma。",
    ],
    ja: [
      "Android と Windows 向けの最初のリリース。",
      "外部エージェント向けの 6 つのツールを備えた MCP サーバー。",
      "アラビア語（RTL）を含む 12 言語の UI。",
      "HTML、React、Flutter、Tailwind、PNG、SVG、PDF、Figma にエクスポート。",
    ],
    ko: [
      "Android와 Windows를 위한 첫 릴리스.",
      "외부 에이전트를 위한 6개 도구의 MCP 서버.",
      "아랍어(RTL)를 포함한 12개 UI 언어.",
      "HTML, React, Flutter, Tailwind, PNG, SVG, PDF, Figma로 내보내기.",
    ],
    ru: [
      "Первый релиз для Android и Windows.",
      "MCP-сервер с 6 инструментами для внешних агентов.",
      "12 языков интерфейса, включая арабский (RTL).",
      "Экспорт в HTML, React, Flutter, Tailwind, PNG, SVG, PDF и Figma.",
    ],
    de: [
      "Erste Version für Android und Windows.",
      "MCP-Server mit 6 Tools für externe Agenten.",
      "12 UI-Sprachen, einschließlich Arabisch (RTL).",
      "Export nach HTML, React, Flutter, Tailwind, PNG, SVG, PDF und Figma.",
    ],
    ar: [
      "أول إصدار لنظامي Android وWindows.",
      "خادم MCP مع 6 أدوات للوكلاء الخارجيين.",
      "12 لغة واجهة، بما في ذلك العربية (RTL).",
      "تصدير إلى HTML وReact وFlutter وTailwind وPNG وSVG وPDF وFigma.",
    ],
    fr: [
      "Première version pour Android et Windows.",
      "Serveur MCP avec 6 outils pour les agents externes.",
      "12 langues d'interface, dont l'arabe (RTL).",
      "Export vers HTML, React, Flutter, Tailwind, PNG, SVG, PDF et Figma.",
    ],
    pt: [
      "Primeira versão para Android e Windows.",
      "Servidor MCP com 6 ferramentas para agentes externos.",
      "12 idiomas de interface, incluindo árabe (RTL).",
      "Exportação para HTML, React, Flutter, Tailwind, PNG, SVG, PDF e Figma.",
    ],
    th: [
      "รีลีสแรกสำหรับ Android และ Windows",
      "เซิร์ฟเวอร์ MCP พร้อม 6 เครื่องมือสำหรับเอเจนต์ภายนอก",
      "12 ภาษาของอินเทอร์เฟซ รวมถึงอาหรับ (RTL)",
      "ส่งออกเป็น HTML, React, Flutter, Tailwind, PNG, SVG, PDF และ Figma",
    ],
    fil: [
      "Unang release para sa Android at Windows.",
      "MCP server na may 6 na tool para sa external agents.",
      "12 UI languages, kasama ang Arabic (RTL).",
      "I-export sa HTML, React, Flutter, Tailwind, PNG, SVG, PDF, at Figma.",
    ],
  },
  downloads: {
    windows: {
      fileName: `Centauri-Setup-${version}.exe`,
      // Perkiraan; sesuaikan dengan ukuran installer hasil build.
      size: "~30 MB",
      requirements: "Windows 10+ (x64)",
      // Isi URL asset GitHub Release setelah rilis.
      url: "",
    },
    android: {
      fileName: `Centauri-${version}.apk`,
      size: "± 72 MB",
      requirements: "Android 7.0+ (API 24)",
      // Isi URL asset GitHub Release setelah rilis.
      url: "",
    },
  },
};

export const downloadUrl = (item) => item?.url?.trim() || site.releases;
