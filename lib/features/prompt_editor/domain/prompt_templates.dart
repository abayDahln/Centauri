/// System prompt internal yang memaksa AI menghasilkan output HTML/Tailwind
/// yang valid dan konsisten dengan design system Centauri (Fase 3).
const String uiSystemPrompt = '''
You are Centauri's UI Engine, an expert front-end engineer and product designer.
Generate ONE complete, self-contained HTML document based on the user's request.

STRICT RULES:
- Return ONLY the HTML document. No markdown, no explanations, no comments outside the HTML.
- Start with <!DOCTYPE html> and include <html lang="en">.
- Use Tailwind CSS via CDN: <script src="https://cdn.tailwindcss.com"></script>
- Put any custom CSS inside a <style> tag in the document head.
- Dark mode first. Professional, high-contrast, minimal aesthetic
  (inspired by Vercel, Linear, Figma). Prefer neutral zinc grays
  (#09090B, #18181B, #27272A, #3F3F46) with a single blue accent (#3B82F6).
- Typography: Inter for text, JetBrains Mono for code/numeric values.
- Make the layout responsive and content realistic (no lorem ipsum placeholders).
- Interactive states must be visual only (hover/focus), no external JS dependencies.
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
        'Use the default Centauri dark theme: zinc grays with a single blue (#3B82F6) accent, Inter typography, 8px radii, subtle 1px borders, no shadows.',
  ),
  DesignTokenPreset(
    id: 'electric',
    label: 'Electric',
    promptFragment:
        'Design tokens: vibrant violet (#8B5CF6) as primary accent, cyan (#22D3EE) highlights, gradient buttons (135deg), pill-shaped radii (999px), glowing focus rings.',
  ),
  DesignTokenPreset(
    id: 'paper',
    label: 'Paper Light',
    promptFragment:
        'Design tokens: light theme on off-white (#FAFAFA) surfaces, hairline borders (#E4E4E7), near-black (#18181B) text, 6px radii, generous whitespace, no heavy shadows.',
  ),
  DesignTokenPreset(
    id: 'brutalist',
    label: 'Brutalist',
    promptFragment:
        'Design tokens: bold brutalist style, thick 2px black charcoal borders (#18181B), offset hard shadows (4px 4px 0), monospace headings (JetBrains Mono), sharp 0px radii.',
  ),
];
