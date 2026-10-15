import 'package:centauri/features/canvas_preview/data/services/canvas_webview_service.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/canvas_provider.dart';
import 'package:centauri/features/code_exporter/data/frame_export_service.dart';
import 'package:centauri/features/code_exporter/domain/code_transformer.dart';
import 'package:centauri/features/code_exporter/domain/export_format.dart';
import 'package:centauri/features/code_exporter/domain/html_to_tailwind.dart';
import 'package:centauri/features/mcp/data/mcp_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildSelectedNodeContext (Fase 4b)', () {
    test('describes tag, box, and styles', () {
      const geometry = NodeGeometry(
        id: 'n3',
        tag: 'button',
        x: 10,
        y: 20,
        width: 120,
        height: 44,
        styles: {'color': 'rgb(255, 255, 255)', 'fontSize': '14px'},
      );
      final context = buildSelectedNodeContext(
        geometry: geometry,
        frameTitle: 'Login',
      );
      expect(context, contains('[SELECTED NODE]'));
      expect(context, contains('<button>'));
      expect(context, contains('120x44px'));
      expect(context, contains('Login'));
      expect(context, contains('font-size:14px'));
    });

    test('omits empty styles section', () {
      const geometry = NodeGeometry(
        id: 'n1',
        tag: 'div',
        x: 0,
        y: 0,
        width: 50,
        height: 50,
      );
      final context = buildSelectedNodeContext(
        geometry: geometry,
        frameTitle: 'Home',
      );
      expect(context, contains('[SELECTED NODE]'));
      expect(context, isNot(contains('styles=')));
    });
  });

  group('cssToTailwind (Fase 4c)', () {
    test('maps declarations to arbitrary properties', () {
      expect(
        cssToTailwind('color: #fff; font-size: 14px;'),
        '[color:#fff] [font-size:14px]',
      );
    });

    test('converts spaces to underscores and handles important', () {
      expect(
        cssToTailwind('margin: 0 auto; display: none !important;'),
        '[margin:0_auto] ![display:none]',
      );
    });

    test('ignores empty and malformed declarations', () {
      expect(cssToTailwind(';;;'), isEmpty);
      expect(cssToTailwind('color;'), isEmpty);
    });
  });

  group('transformCode tailwind (Fase 4c)', () {
    test('replaces inline style with classes, keeps existing class', () {
      const html =
          '<div class="card" style="color: red; padding: 8px;">Hi</div>';
      final out = transformCode(
        htmlSource: html,
        format: CodeFormat.tailwind,
      );
      expect(out, contains('class="card [color:red] [padding:8px]"'));
      expect(out, isNot(contains('style=')));
    });
  });

  group('McpServer.toolSchemas (Fase 4d)', () {
    test('exposes the 7 documented tools', () {
      final names = McpServer.toolSchemas()
          .map((t) => t['name'] as String)
          .toSet();
      expect(
        names,
        containsAll([
          'get_canvas_structure',
          'get_selected_node',
          'get_node_html',
          'add_node',
          'update_node',
          'delete_node',
          'rearrange_layout',
        ]),
      );
    });
  });

  group('FrameExportService (Fase 3 regression)', () {
    test('service is constructible', () {
      expect(FrameExportService.new, isNotNull);
    });
  });
}
