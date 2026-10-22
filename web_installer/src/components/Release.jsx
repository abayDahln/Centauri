import { Check, ExternalLink } from "lucide-react";
import { useLanguage } from "../i18n/LanguageProvider";

function formatDate(value, language) {
  if (!value) return "";

  const date = new Date(`${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return value;

  try {
    return new Intl.DateTimeFormat(language, { dateStyle: "long" }).format(
      date,
    );
  } catch {
    return value;
  }
}

export default function Release({ release }) {
  const { language, t } = useLanguage();

  const highlights = Array.isArray(release.highlights)
    ? release.highlights
    : release.highlights[language] ?? release.highlights.en ?? [];

  const releasedAt = formatDate(release.releasedAt, language);

  return (
    <section className="section section-soft" id="rilis">
      <div className="container">
        <div className="section-head">
          <p className="section-kicker">{t("release.kicker")}</p>
          <h2>{t("release.title")}</h2>
          <p className="section-lead">{t("release.lead")}</p>
        </div>

        <div className="release-card">
          <div className="release-main">
            <div className="release-heading">
              <span className="release-version" dir="ltr">
                v{release.version}
              </span>
              <span className="release-date">{releasedAt}</span>
            </div>

            <h3>Centauri {release.version}</h3>

            <a
              className="text-link"
              href={release.notesUrl}
              target="_blank"
              rel="noreferrer"
            >
              {t("release.viewAll")}
              <ExternalLink size={14} aria-hidden="true" />
            </a>
          </div>

          <ul className="release-highlights">
            {highlights.map((highlight, index) => (
              <li key={`${release.version}-${index}`}>
                <Check size={15} aria-hidden="true" />
                <bdi>{highlight}</bdi>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
