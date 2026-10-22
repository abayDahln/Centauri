import { useEffect, useRef, useState } from "react";
import { Check, Globe } from "lucide-react";
import { useLanguage } from "../i18n/LanguageProvider";

export default function LanguageMenu() {
  const { language, setLanguage, languages, t } = useLanguage();
  const [open, setOpen] = useState(false);
  const wrapperRef = useRef(null);
  const buttonRef = useRef(null);

  useEffect(() => {
    if (!open) return undefined;

    const handlePointerDown = (event) => {
      if (!wrapperRef.current?.contains(event.target)) {
        setOpen(false);
      }
    };

    const handleKeyDown = (event) => {
      if (event.key === "Escape") {
        setOpen(false);
        buttonRef.current?.focus();
      }
    };

    document.addEventListener("pointerdown", handlePointerDown);
    document.addEventListener("keydown", handleKeyDown);

    return () => {
      document.removeEventListener("pointerdown", handlePointerDown);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [open]);

  const chooseLanguage = (code) => {
    setLanguage(code);
    setOpen(false);
    buttonRef.current?.focus();
  };

  return (
    <div className="language-menu" ref={wrapperRef}>
      <button
        ref={buttonRef}
        type="button"
        className="icon-button"
        onClick={() => setOpen((current) => !current)}
        aria-label={t("a11y.language")}
        aria-haspopup="menu"
        aria-expanded={open}
        title={t("language.title")}
      >
        <Globe size={18} aria-hidden="true" />
      </button>

      {open && (
        <div
          className="language-dropdown"
          role="menu"
          aria-label={t("language.title")}
        >
          <p className="language-dropdown-title">{t("language.title")}</p>

          {languages.map((item) => {
            const selected = item.code === language;

            return (
              <button
                key={item.code}
                type="button"
                role="menuitem"
                className="language-option"
                aria-current={selected ? "true" : undefined}
                onClick={() => chooseLanguage(item.code)}
              >
                <span className="language-option-name">
                  <span lang={item.code} dir={item.dir}>
                    {item.nativeName}
                  </span>
                  {item.englishName !== item.nativeName && (
                    <span className="language-option-english" lang="en">
                      {item.englishName}
                    </span>
                  )}
                </span>

                {selected && <Check size={14} aria-hidden="true" />}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
