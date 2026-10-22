import {
  Bot,
  Code2,
  KeyRound,
  LayoutDashboard,
  MousePointerClick,
  Smartphone,
} from "lucide-react";
import { useLanguage } from "../i18n/LanguageProvider";

const featureIcons = [
  { key: "byok", icon: KeyRound },
  { key: "multipage", icon: LayoutDashboard },
  { key: "fluid", icon: Smartphone },
  { key: "edit", icon: MousePointerClick },
  { key: "export", icon: Code2 },
  { key: "mcp", icon: Bot },
];

export default function Features() {
  const { t } = useLanguage();

  return (
    <section className="section" id="fitur">
      <div className="container">
        <div className="section-head">
          <p className="section-kicker">{t("features.kicker")}</p>
          <h2>{t("features.title")}</h2>
          <p className="section-lead">{t("features.lead")}</p>
        </div>

        <div className="features-grid">
          {featureIcons.map(({ key, icon: Icon }) => (
            <article className="feature-card" key={key}>
              <span className="feature-icon">
                <Icon size={19} aria-hidden="true" />
              </span>
              <h3>{t(`features.${key}.title`)}</h3>
              <p>{t(`features.${key}.body`)}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
