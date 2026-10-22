import { ChevronDown } from "lucide-react";
import { useLanguage } from "../i18n/LanguageProvider";

const faqNumbers = [1, 2, 3, 4, 5];

export default function FAQ() {
  const { t } = useLanguage();

  return (
    <section className="section" id="faq">
      <div className="container">
        <div className="section-head">
          <p className="section-kicker">{t("faq.kicker")}</p>
          <h2>{t("faq.title")}</h2>
          <p className="section-lead">{t("faq.lead")}</p>
        </div>

        <div className="faq-list">
          {faqNumbers.map((number) => (
            <details key={number}>
              <summary>
                <span>{t(`faq.q${number}`)}</span>
                <ChevronDown
                  size={18}
                  className="chevron"
                  aria-hidden="true"
                />
              </summary>
              <p>{t(`faq.a${number}`)}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}
