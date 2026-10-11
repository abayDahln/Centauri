/// System prompt internal yang memaksa AI menghasilkan SATU file HTML
/// sepenuhnya self-contained: semua CSS dan JS inline, tanpa CDN, tanpa
/// framework, tanpa dependency eksternal. Output bisa langsung disimpan
/// sebagai .html dan dijalankan offline.
const String uiSystemPrompt = '''
You are Centauri's UI Engine, an expert front-end engineer and product designer.
Generate ONE complete, fully self-contained HTML document based on the user's request.

STRICT RULES:
- Return ONLY the HTML document. No markdown, no explanations, no comments outside the HTML.
- Start with <!DOCTYPE html> and include <html lang="en"> and a strict
  <meta name="viewport" content="width=device-width, initial-scale=1"> tag.
- ALL CSS must be written by hand inside a single <style> tag in the <head>.
- FORBIDDEN: external stylesheets, <link> tags, CDN scripts, CSS frameworks
  (no Tailwind CDN), icon libraries, web fonts, or any network request.
- Use system font stacks instead of web fonts:
  font-family: Inter, "Plus Jakarta Sans", system-ui, sans-serif; and
  font-family: "JetBrains Mono", "Fira Code", ui-monospace, monospace; for code.
- JavaScript is allowed and encouraged: write vanilla JS inline in one <script>
  tag at the end of <body>. No external libraries, no imports, no fetch().
  Use it for real interactivity (tabs, accordion, dropdown, modal, form
  validation, counter) whenever it makes the UI feel complete.
- Write all CSS from scratch for the design tokens below. Do not reference
  any utility-class system.
- Dark mode first. Professional, high-contrast, minimal aesthetic
  (inspired by Vercel, Linear, Figma). Prefer neutral zinc grays
  (#09090B, #18181B, #27272A, #3F3F46) with a single blue accent (#3B82F6).
- Use media queries for responsiveness; layouts must adapt from 360px to desktop.
- Make content realistic (no lorem ipsum placeholders).
- Keep everything in ONE file: styles in <style>, scripts in <script>,
  icons as inline SVG.
- Apply any design token provided by the user at the end of their message.
''';

/// Design token preset yang bisa dipilih pengguna sebelum generasi (FR-02).
class DesignTokenPreset {
  const DesignTokenPreset({
    required this.id,
    required this.label,
    required this.promptFragment,
  });

  final String id;
  final String label;
  final String promptFragment;
}

const List<DesignTokenPreset> designTokenPresets = [
  DesignTokenPreset(
    id: 'current',
    label: 'Current',
    promptFragment:
        'Design tokens (write the CSS yourself): zinc grays (#09090B / #18181B / #27272A / #3F3F46) with a single blue accent (#3B82F6), Inter typography, 6-8px radii, subtle 1px borders (#27272A), no shadows, high contrast.',
  ),
  DesignTokenPreset(
    id: 'electric',
    label: 'Electric',
    promptFragment:
        'Design tokens (write the CSS yourself): vibrant violet (#8B5CF6) as primary accent, cyan (#22D3EE) highlights, gradient buttons (135deg), pill-shaped radii (999px), glowing focus rings on dark background.',
  ),
  DesignTokenPreset(
    id: 'paper',
    label: 'Paper Light',
    promptFragment:
        'Design tokens (write the CSS yourself): light theme on off-white (#FAFAFA) surfaces, hairline borders (#E4E4E7), near-black (#18181B) text, 6px radii, generous whitespace, no heavy shadows.',
  ),
  DesignTokenPreset(
    id: 'brutalist',
    label: 'Brutalist',
    promptFragment:
        'Design tokens (write the CSS yourself): bold brutalist style, thick 2px charcoal borders (#18181B), offset hard shadows (4px 4px 0 #18181B), monospace headings (JetBrains Mono, system monospace), sharp 0px radii, high contrast.',
  ),
];
