import 'package:html/parser.dart' as html;

import 'export_format.dart';
import 'html_to_flutter.dart';
import 'html_to_react.dart';
import 'html_to_tailwind.dart';

/// Membersihkan dan menormalkan output HTML AI menjadi HTML murni.
String transformToHtml(String htmlSource) {
  final document = html.parse(htmlSource);
  return document.outerHtml;
}

/// Facade transformasi kode: satu entry point untuk semua format (FR-05).
String transformCode({required String htmlSource, required CodeFormat format}) {
  switch (format) {
    case CodeFormat.html:
      return transformToHtml(htmlSource);
    case CodeFormat.reactJsx:
      return HtmlToReactTransformer().transform(htmlSource);
    case CodeFormat.flutterDart:
      return HtmlToFlutterTransformer().transform(htmlSource);
    case CodeFormat.tailwind:
      return HtmlToTailwindTransformer().transform(htmlSource);
  }
}
