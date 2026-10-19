import 'package:html/parser.dart' as html;

import '../../../core/errors/app_error.dart';
import 'export_format.dart';
import 'html_to_flutter.dart';
import 'html_to_react.dart';
import 'html_to_tailwind.dart';

/// Dilempar ketika HTML dari Alpha tidak bisa diubah ke format target.
/// Dipakai UI untuk menampilkan pesan yang bisa dibaca pengguna, bukan
/// stack trace dari parser.
class CodeTransformException extends AppErrorDetails implements Exception {
  const CodeTransformException(
    super.code, {
    super.detail,
    super.formats,
    this.format,
    this.cause,
  });

  /// Format yang gagal dihasilkan, null jika sumbernya sendiri bermasalah.
  final CodeFormat? format;

  /// Error asli dari parser/transformer, untuk log.
  final Object? cause;

  @override
  String toString() => debugLabel;
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
    throw const CodeTransformException(AppErrorCode.transformNoCode);
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
      AppErrorCode.transformFailed,
      format: format,
      formats: format.label,
      detail: '$error',
      cause: error,
    );
  }
}
