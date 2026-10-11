import 'package:centauri/features/code_exporter/domain/code_transformer.dart';
import 'package:centauri/features/code_exporter/domain/export_format.dart';
import 'package:flutter_test/flutter_test.dart';

const sampleHtml = '''
<!DOCTYPE html>
<html>
<head><title>Test</title></head>
<body>
  <div style="background-color: #18181B; padding: 16px">
    <h1 style="color: #FAFAFA">Dashboard</h1>
    <p class="text-sm">Ringkasan aktivitas harian.</p>
    <button type="button">Lihat laporan</button>
    <img src="https://example.com/chart.png" alt="chart">
    <br>
    <ul>
      <li>Pendapatan naik 12%</li>
      <li>Pengguna aktif 1.204</li>
    </ul>
  </div>
</body>
</html>
''';

void main() {
  group('transformCode - React', () {
    final result = transformCode(
      htmlSource: sampleHtml,
      format: CodeFormat.reactJsx,
    );

    test('wraps output in a default exported component', () {
      expect(result, contains('export default function GeneratedUI()'));
    });

    test('converts class attribute to className', () {
      expect(result, contains('className="text-sm"'));
      expect(result.contains(' class="'), isFalse);
    });

    test('converts inline style to JSX object syntax', () {
      expect(result, contains("style={{color: '#FAFAFA'}}"));
      expect(
        result,
        contains("style={{backgroundColor: '#18181B', padding: 16}}"),
      );
    });

    test('self-closes void elements', () {
      expect(
        result,
        contains('<img src="https://example.com/chart.png" alt="chart" />'),
      );
      expect(result, contains('<br />'));
    });
  });

  group('transformCode - Flutter', () {
    final result = transformCode(
      htmlSource: sampleHtml,
      format: CodeFormat.flutterDart,
    );

    test('generates a StatelessWidget with Scaffold', () {
      expect(
        result,
        contains('class GeneratedUIScreen extends StatelessWidget'),
      );
      expect(result, contains('return Scaffold('));
    });

    test('maps headings to Text widgets with sizes', () {
      expect(result, contains('Text('));
      expect(result, contains('fontSize: 30'));
    });

    test('maps buttons to ElevatedButton', () {
      expect(result, contains('ElevatedButton('));
      expect(result, contains("Text('Lihat laporan')"));
    });

    test('maps list items inside a Column', () {
      expect(result, contains('Column('));
      expect(result, contains("Text('Pendapatan naik 12%')"));
    });

    test('translates background color to BoxDecoration', () {
      expect(result, contains('BoxDecoration('));
      expect(result, contains('Color(0xFF18181B)'));
    });

    test('skips script/style head tags', () {
      final withTags =
          '<html><head><style>body{}</style></head>'
          '<body><div><h2>Judul</h2></div></body></html>';
      final transformed = transformCode(
        htmlSource: withTags,
        format: CodeFormat.flutterDart,
      );
      expect(transformed.contains('body{}'), isFalse);
      expect(transformed, contains("'Judul'"));
      expect(transformed, contains('Text('));
      expect(transformed, contains('fontSize: 26'));
    });
  });

  group('transformCode - HTML', () {
    test('normalizes and preserves content', () {
      final result = transformCode(
        htmlSource: sampleHtml,
        format: CodeFormat.html,
      );
      expect(result, contains('Dashboard'));
      expect(result, contains('<html'));
      expect(result, contains('</html>'));
    });
  });

  group('transformCode - robustness', () {
    test('handles markdown-fenced AI output', () {
      final raw =
          'Sure, here you go:\n'
          '```html\n<html><body><h1>Hi</h1></body></html>\n```';
      final result = transformCode(
        htmlSource: raw,
        format: CodeFormat.flutterDart,
      );
      expect(result, contains('Text('));
    });

    test('handles empty body without crashing', () {
      final result = transformCode(
        htmlSource: '<html><body></body></html>',
        format: CodeFormat.flutterDart,
      );
      expect(result, contains('class GeneratedUIScreen'));
    });
  });
}
