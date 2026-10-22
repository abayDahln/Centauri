import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  DEFAULT_LANGUAGE,
  LANGUAGE_KEY,
  getLanguage,
  languages,
} from "./languages";
import { translations } from "./translations";

const LanguageContext = createContext(null);

function resolve(object, path) {
  return path
    .split(".")
    .reduce((value, key) => (value == null ? undefined : value[key]), object);
}

function interpolate(value, vars) {
  if (typeof value !== "string" || !vars) return value;

  return value.replace(/\{(\w+)\}/g, (match, key) =>
    Object.prototype.hasOwnProperty.call(vars, key)
      ? String(vars[key])
      : match,
  );
}

function getInitialLanguage() {
  try {
    const saved = localStorage.getItem(LANGUAGE_KEY);
    if (saved && translations[saved]) return saved;
  } catch {
    // localStorage bisa tidak tersedia di mode privasi.
  }

  return DEFAULT_LANGUAGE;
}

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState(getInitialLanguage);
  const languageMeta = useMemo(() => getLanguage(language), [language]);

  const t = useCallback(
    (key, vars) => {
      const value =
        resolve(translations[language], key) ??
        resolve(translations[DEFAULT_LANGUAGE], key);

      // Array dipakai untuk daftar (mis. fitur di kartu unduhan).
      if (Array.isArray(value)) return value;

      return interpolate(value ?? key, vars);
    },
    [language],
  );

  useEffect(() => {
    const root = document.documentElement;
    root.lang = language;
    root.dir = languageMeta.dir;

    try {
      localStorage.setItem(LANGUAGE_KEY, language);
    } catch {
      // Abaikan kalau penyimpanan tidak tersedia.
    }

    const title = t("meta.title");
    const description = t("meta.description");

    document.title = title;
    document
      .querySelector('meta[name="description"]')
      ?.setAttribute("content", description);
    document
      .querySelector('meta[property="og:title"]')
      ?.setAttribute("content", title);
    document
      .querySelector('meta[property="og:description"]')
      ?.setAttribute("content", description);
  }, [language, languageMeta, t]);

  const value = useMemo(
    () => ({ language, setLanguage, languageMeta, languages, t }),
    [language, languageMeta, t],
  );

  return (
    <LanguageContext.Provider value={value}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);

  if (!context) {
    throw new Error("useLanguage harus dipakai di dalam LanguageProvider.");
  }

  return context;
}
