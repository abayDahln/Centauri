import GithubIcon from "./GithubIcon";
import logo from "../assets/centauri-tile.png";
import { site } from "../config";
import { useLanguage } from "../i18n/LanguageProvider";

export default function Footer() {
  const { t } = useLanguage();
  const year = new Date().getFullYear();

  return (
    <footer className="site-footer">
      <div className="container">
        <div className="footer-grid">
          <div className="footer-brand">
            <img src={logo} alt="" width="36" height="36" />
            <div>
              <strong>{site.name}</strong>
              <span>{site.tagline}</span>
            </div>
          </div>

          <nav className="footer-links" aria-label={t("a11y.footerNav")}>
            <a href={site.github} target="_blank" rel="noreferrer">
              <GithubIcon size={15} />
              {t("footer.github")}
            </a>
            <a href={site.releases} target="_blank" rel="noreferrer">
              {t("footer.releases")}
            </a>
            <a href={site.license} target="_blank" rel="noreferrer">
              {t("footer.license")}
            </a>
            <a href="#top">{t("footer.backToTop")}</a>
          </nav>
        </div>

        <div className="footer-bottom">
          <span>
            {t("footer.copyright", { year })} {t("footer.builtWith")}
          </span>
          <span>{t("footer.platforms")}</span>
        </div>
      </div>
    </footer>
  );
}
