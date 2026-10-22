import { useLanguage } from "../i18n/LanguageProvider";

const stepNumbers = ["01", "02", "03"];

export default function HowItWorks() {
  const { t } = useLanguage();

  return (
    <section className="section section-soft" id="alur">
      <div className="container">
        <div className="section-head">
          <p className="section-kicker">{t("how.kicker")}</p>
          <h2>{t("how.title")}</h2>
          <p className="section-lead">{t("how.lead")}</p>
        </div>

        <div className="steps">
          {stepNumbers.map((number, index) => (
            <article className="step" key={number}>
              <span className="step-number">{number}</span>
              <h3>{t(`how.step${index + 1}.title`)}</h3>
              <p>{t(`how.step${index + 1}.body`)}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
