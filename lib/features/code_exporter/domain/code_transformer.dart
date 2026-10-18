import 'package:html/parser.dart' as html;

import 'export_format.dart';
import 'html_to_flutter.dart';
import 'html_to_react.dart';
import 'html_to_tailwind.dart';

/// Dilempar ketika HTML dari Alpha tidak bisa diubah ke format target.
/// Dipakai UI untuk menampilkan pesan yang bisa dibaca pengguna, bukan
/// stack trace dari parser.
class CodeTransformException implements Exception {
  CodeTransformException(this.message, {this.format, this.cause});

  /// Pesan siap tampil di UI.
  final String message;

  /// Format yang gagal dihasilkan, null jika sumbernya sendiri bermasalah.
  final CodeFormat? format;

  /// Error asli dari parser/transformer, untuk log.
  final Object? cause;

  @override
  String toString() => message;
}

/// Membersihkan dan menormalkan output HTML AI menjadi HTML murni.
String transformToHtml(String htmlSource) {
  final document = html.parse(htmlSource);
  return document.outerHtml;
}

/// Facade transformasi kode: satu entry point untuk semua format (FR-05).
///
/// Output AI bisa berupa apa saja, jadi semua kegagalan parser ditangkap dan
/// dilempar ulang sebagai [CodeTransformException] agar tidak menjatuhkan UI.
String transformCode({required String htmlSource, required CodeFormat format}) {
  if (htmlSource.trim().isEmpty) {
    throw CodeTransformException('Halaman ini belum punya kode untuk diubah.');
  }

  try {
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
  } catch (error) {
    throw CodeTransformException(
      'Kode dari Alpha tidak bisa diubah ke ${format.label}.',
      format: format,
      cause: error,
    );
  }
}
