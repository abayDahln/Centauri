import { useEffect, useState } from "react";
import Nav from "./components/Nav";
import Hero from "./components/Hero";
import Features from "./components/Features";
import HowItWorks from "./components/HowItWorks";
import Install from "./components/Install";
import Release from "./components/Release";
import FAQ from "./components/FAQ";
import Footer from "./components/Footer";
import { useLanguage } from "./i18n/LanguageProvider";
import { release } from "./config";

const THEME_KEY = "centauri-theme";

function getInitialTheme() {
  try {
    const saved = localStorage.getItem(THEME_KEY);
    if (saved === "light" || saved === "dark") return saved;
  } catch {
    // localStorage bisa tidak tersedia di mode privasi.
  }
  return "dark";
}

export default function App() {
  const [theme, setTheme] = useState(getInitialTheme);
  const { t } = useLanguage();

  useEffect(() => {
    document.documentElement.dataset.theme = theme;

    const themeColor = document.querySelector('meta[name="theme-color"]');
    if (themeColor) {
      themeColor.setAttribute(
        "content",
        theme === "dark" ? "#07080b" : "#f6f7f8",
      );
    }

    try {
      localStorage.setItem(THEME_KEY, theme);
    } catch {
      // Abaikan kalau penyimpanan tidak tersedia.
    }
  }, [theme]);

  const toggleTheme = () =>
    setTheme((current) => (current === "dark" ? "light" : "dark"));

  return (
    <>
      <a className="skip-link" href="#main">
        {t("a11y.skip")}
      </a>
      <Nav theme={theme} onToggleTheme={toggleTheme} />
      <main id="main">
        <Hero />
        <Features />
        <HowItWorks />
        <Install release={release} />
        <Release release={release} />
        <FAQ />
      </main>
      <Footer />
    </>
  );
}
