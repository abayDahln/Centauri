import { Fragment } from "react";

// Menandai bagian judul yang memakai gradient. Marker dipakai supaya urutan
// kata tetap bisa diterjemahkan tanpa memecah kalimat di komponen.
export function AccentText({ text }) {
  const start = text.indexOf("{accent}");
  const end = text.indexOf("{/accent}");

  if (start === -1 || end === -1 || end < start) return text;

  return (
    <>
      {text.slice(0, start)}
      <span className="gradient-text">{text.slice(start + 8, end)}</span>
      {text.slice(end + 9)}
    </>
  );
}

// Menandai nama brand di dalam judul yang diterjemahkan.
export function BrandText({ text, brand }) {
  const parts = text.split("{brand}");

  return parts.map((part, index) => (
    <Fragment key={index}>
      {part}
      {index < parts.length - 1 && (
        <span className="brand-accent">{brand}</span>
      )}
    </Fragment>
  ));
}
