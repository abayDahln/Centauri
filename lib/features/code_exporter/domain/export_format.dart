/// Format ekspor kode (FR-05).
enum CodeFormat {
  html('HTML', 'html', 'html'),
  reactJsx('React (JSX)', 'javascript', 'jsx'),
  flutterDart('Flutter (Dart)', 'dart', 'dart');

  const CodeFormat(this.label, this.highlightLanguage, this.fileExtension);

  final String label;

  /// Identifier bahasa untuk flutter_highlight.
  final String highlightLanguage;

  final String fileExtension;
}
