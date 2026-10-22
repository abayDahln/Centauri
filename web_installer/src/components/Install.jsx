import { AlertTriangle, Check, ShieldCheck } from "lucide-react";
import AndroidIcon from "./AndroidIcon";
import WindowsIcon from "./WindowsIcon";
import { BrandText } from "./RichText";
import { downloadUrl, site } from "../config";
import { useLanguage } from "../i18n/LanguageProvider";

export default function Install({ release }) {
  const { t } = useLanguage();
  const { windows, android } = release.downloads;

  const cards = [
    {
      key: "windows",
      platform: "Windows",
      category: t("install.categoryDesktop"),
      icon: WindowsIcon,
      item: windows,
      features: t("install.windows.features"),
      note: t("install.windows.note"),
      featured: true,
      ariaLabel: t("a11y.downloadWindows"),
    },
    {
      key: "android",
      platform: "Android",
      category: t("install.categoryMobile"),
      icon: AndroidIcon,
      item: android,
      features: t("install.android.features"),
      note: t("install.android.note"),
      featured: false,
      ariaLabel: t("a11y.downloadAndroid"),
    },
  ];

  return (
    <section className="section download-section" id="download">
      <div className="container">
        <div className="download-head">
          <h2 className="download-title">
            <BrandText text={t("install.title")} brand={site.name} />
          </h2>
          <p className="download-lead">{t("install.lead")}</p>
        </div>

        <div className="download-grid">
          {cards.map(
            ({
              key,
              platform,
              category,
              icon: Icon,
              item,
              features,
              note,
              featured,
              ariaLabel,
            }) => (
              <article
                className={`download-card${featured ? " featured" : ""}`}
                key={key}
              >
                {featured && (
                  <span className="download-badge">
                    {t("install.mostPicked")}
                  </span>
                )}

                <p className="download-category">{category}</p>
                <h3>{platform}</h3>
                <span className="download-version" dir="ltr">
                  v{release.version}
                </span>

                <div className="download-icon-wrap">
                  <Icon size={38} />
                </div>

                <p className="download-size" dir="ltr">
                  {item.size}
                </p>
                <span className="download-size-label">
                  {t("install.fileSize")}
                </span>

                <ul className="download-features">
                  {features.map((feature, index) => (
                    <li key={`${key}-${index}`}>
                      <Check size={15} aria-hidden="true" />
                      <bdi>{feature}</bdi>
                    </li>
                  ))}
                </ul>

                <p className="download-note">
                  <AlertTriangle size={15} aria-hidden="true" />
                  <span>{note}</span>
                </p>

                <a
                  className="button button-primary"
                  href={downloadUrl(item)}
                  target="_blank"
                  rel="noreferrer"
                  aria-label={ariaLabel}
                  title={item.fileName}
                >
                  {t("install.download")}
                </a>
              </article>
            ),
          )}
        </div>

        <p className="download-safe">
          <ShieldCheck size={15} aria-hidden="true" />
          {t("install.safe")}
        </p>
      </div>
    </section>
  );
}
