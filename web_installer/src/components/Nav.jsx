import { Download, Moon, Sun } from "lucide-react";
import GithubIcon from "./GithubIcon";
import LanguageMenu from "./LanguageMenu";
import logo from "../assets/centauri-tile.png";
import { site } from "../config";
import { useLanguage } from "../i18n/LanguageProvider";

export default function Nav({ theme, onToggleTheme }) {
  const isDark = theme === "dark";
  const { t } = useLanguage();

  return (
    <header className="site-header">
      <div className="container nav">
        <a className="brand" href="#top" aria-label={t("a11y.home")}>
          <img src={logo} alt="" width="32" height="32" />
          <span>{site.name}</span>
        </a>

        <nav className="nav-links" aria-label={t("a11y.mainNav")}>
          <a href="#fitur">{t("nav.features")}</a>
          <a href="#alur">{t("nav.how")}</a>
          <a href="#download">{t("nav.install")}</a>
          <a href="#rilis">{t("nav.release")}</a>
          <a href="#faq">{t("nav.faq")}</a>
        </nav>

        <div className="nav-actions">
          <LanguageMenu />

          <button
            type="button"
            className="icon-button"
            onClick={onToggleTheme}
            aria-label={
              isDark ? t("a11y.themeLight") : t("a11y.themeDark")
            }
            title={isDark ? t("theme.light") : t("theme.dark")}
          >
            {isDark ? (
              <Sun size={18} aria-hidden="true" />
            ) : (
              <Moon size={18} aria-hidden="true" />
            )}
          </button>

          <a
            className="icon-button"
            href={site.github}
            target="_blank"
            rel="noreferrer"
            aria-label={t("a11y.github")}
            title="GitHub"
          >
            <GithubIcon size={18} />
          </a>

          <a className="button button-small" href="#download">
            <Download size={15} aria-hidden="true" />
            {t("nav.download")}
          </a>
        </div>
      </div>
    </header>
  );
}
