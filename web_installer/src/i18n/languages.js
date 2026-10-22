// Daftar bahasa harus sama dengan AppLanguage di aplikasi.
// `nativeName` sengaja tidak diterjemahkan; `englishName` membantu pengguna
// yang belum mengenali aksara bahasa tersebut.
export const DEFAULT_LANGUAGE = "en";
export const LANGUAGE_KEY = "centauri-language";

export const languages = [
  {
    code: "en",
    nativeName: "English",
    englishName: "English",
    dir: "ltr",
  },
  {
    code: "id",
    nativeName: "Bahasa Indonesia",
    englishName: "Indonesian",
    dir: "ltr",
  },
  {
    code: "zh",
    nativeName: "简体中文",
    englishName: "Chinese (Simplified)",
    dir: "ltr",
  },
  {
    code: "ja",
    nativeName: "日本語",
    englishName: "Japanese",
    dir: "ltr",
  },
  {
    code: "ko",
    nativeName: "한국어",
    englishName: "Korean",
    dir: "ltr",
  },
  {
    code: "ru",
    nativeName: "Русский",
    englishName: "Russian",
    dir: "ltr",
  },
  {
    code: "de",
    nativeName: "Deutsch",
    englishName: "German",
    dir: "ltr",
  },
  {
    code: "ar",
    nativeName: "العربية",
    englishName: "Arabic",
    dir: "rtl",
  },
  {
    code: "fr",
    nativeName: "Français",
    englishName: "French",
    dir: "ltr",
  },
  {
    code: "pt",
    nativeName: "Português",
    englishName: "Portuguese",
    dir: "ltr",
  },
  {
    code: "th",
    nativeName: "ไทย",
    englishName: "Thai",
    dir: "ltr",
  },
  {
    code: "fil",
    nativeName: "Filipino",
    englishName: "Filipino",
    dir: "ltr",
  },
];

export const getLanguage = (code) =>
  languages.find((language) => language.code === code) ?? languages[0];
