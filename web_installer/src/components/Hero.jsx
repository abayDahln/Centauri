import { ArrowRight, Lock, Monitor, Smartphone } from "lucide-react";
import ProductPreview from "./ProductPreview";
import { useLanguage } from "../i18n/LanguageProvider";
import { AccentText } from "./RichText";

export default function Hero() {
  const { t } = useLanguage();

  return (
    <section className="hero" id="top">
      <div className="hero-glow" aria-hidden="true" />
      <div className="container hero-grid">
        <div className="hero-copy">
          <h1>
            <AccentText text={t("hero.title")} />
          </h1>

          <p className="hero-lead">{t("hero.lead")}</p>

          <div className="hero-actions">
            <a className="button button-primary" href="#download">
              <Monitor size={18} aria-hidden="true" />
              {t("hero.downloadWindows")}
              <ArrowRight
                size={16}
                className="button-arrow"
                aria-hidden="true"
              />
            </a>
            <a className="button button-secondary" href="#download">
              <Smartphone size={18} aria-hidden="true" />
              {t("hero.downloadAndroid")}
            </a>
          </div>

          <div className="hero-meta">
            <span>
              <Lock size={14} aria-hidden="true" />
              {t("hero.metaKey")}
            </span>
            <span className="meta-sep" aria-hidden="true">
              ·
            </span>
            <span dir="ltr">{t("hero.metaWindows")}</span>
            <span className="meta-sep" aria-hidden="true">
              ·
            </span>
            <span dir="ltr">{t("hero.metaAndroid")}</span>
          </div>
        </div>

        <div className="hero-visual">
          <ProductPreview />
        </div>
      </div>
    </section>
  );
}
