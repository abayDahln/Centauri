import 'package:centauri/features/canvas_preview/data/services/canvas_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('injectBridge', () {
    const html =
        '<!DOCTYPE html><html><body><div id="a">Hi</div></body></html>';

    test('injects the bridge script before </body>', () {
      final out = injectBridge(html);
      final bodyClose = out.lastIndexOf('</body>');
      final scriptIndex = out.indexOf('id="centauri-bridge"');
      expect(scriptIndex, greaterThan(0));
      expect(scriptIndex, lessThan(bodyClose));
      // Dokumen asli tidak hilang.
      expect(out, contains('<div id="a">Hi</div>'));
    });

    test('falls back to </html> when there is no </body>', () {
      const fragment = '<div>x</div>';
      final out = injectBridge(fragment);
      expect(out, contains('id="centauri-bridge"'));
      expect(out, contains('<div>x</div>'));
    });

    test('injects exactly once', () {
      final out = injectBridge(html);
      // Tag pembuka bridge selalu diikuti newline; literal di dalam JS bridge
      // tidak, jadi hitungan ini tidak ikut menghitung isi script.
      expect('<script id="centauri-bridge">\n'.allMatches(out).length, 1);
    });

    test('does not inject a second bridge', () {
      final once = injectBridge(html);
      expect(injectBridge(once), once);
    });

    test('exposes the window API used by Dart', () {
      final out = injectBridge(html);
      for (final fn in const [
        'window.centauriSelect',
        'window.centauriHover',
        'window.centauriInspect',
        'window.centauriApplyStyle',
        'window.centauriMoveResize',
        'window.centauriGetHtml',
        'window.centauriGetOuterHtml',
        'window.centauriExportPng',
        'window.centauriGetSize',
        'window.centauriAddNode',
        'window.centauriSetText',
        'window.centauriDeleteNode',
        'window.centauriExportFigma',
      ]) {
        expect(out, contains(fn), reason: 'API $fn harus ada');
      }
    });

    test('bridge defines every identifier it assigns to window', () {
      // Regresi: marker `window.centauriSetLinkIntercept = ...` pernah
      // tersisa tanpa definisinya, sehingga seluruh bridge mati (ReferenceError
      // sebelum boot) dan semua link antar-halaman gagal ("file not found").
      final assignPattern = RegExp(
        r'window\.(centauri\w+)\s*=\s*([A-Za-z_$][\w$]*)',
      );
      final definedPattern = RegExp(r'function\s+([A-Za-z_$][\w$]*)');
      final defined = definedPattern
          .allMatches(canvasBridgeScript)
          .map((m) => m.group(1))
          .toSet();
      final assigned = assignPattern
          .allMatches(canvasBridgeScript)
          .where((m) => m.group(2) != m.group(1))
          .map((m) => m.group(2)!)
          .toSet();
      for (final name in assigned) {
        expect(
          defined,
          contains(name),
          reason: 'fungsi `$name` di-assign ke window tapi tidak didefinisikan',
        );
      }
    });
  });

  group('figma export', () {
    test('serializes the page into a centauri-figma payload', () {
      expect(canvasBridgeScript, contains('centauriExportFigma'));
      expect(canvasBridgeScript, contains("format: 'centauri-figma'"));
      expect(canvasBridgeScript, contains("type: 'figma'"));
      expect(canvasBridgeScript, contains('payload:'));
      expect(canvasBridgeScript, contains("type: 'figmaError'"));
    });

    test('captures bbox, computed style and direct text per node', () {
      expect(canvasBridgeScript, contains('getBoundingClientRect'));
      expect(canvasBridgeScript, contains('__figmaStyles'));
      expect(canvasBridgeScript, contains("'backgroundColor'"));
      expect(canvasBridgeScript, contains('rect:'));
      expect(canvasBridgeScript, contains('text:'));
    });

    test('skips bridge-internal elements from the payload', () {
      expect(
        canvasBridgeScript,
        contains("getAttribute('data-centauri-overlay')"),
      );
    });
  });

  group('link interception', () {
    test('intercepts clicks on <a href> and reports a navigate event', () {
      // Klik link harus di-preventDefault lalu dikirim ke host agar app bisa
      // memuat halaman tujuan tanpa reload WebView.
      expect(canvasBridgeScript, contains("closest('a[href]')"));
      expect(canvasBridgeScript, contains("type: 'navigate'"));
      expect(canvasBridgeScript, contains('href: href'));
      expect(canvasBridgeScript, contains('e.preventDefault()'));
    });

    test('leaves in-page anchors to the browser', () {
      // Anchor (#...) tidak diintersep agar browser bisa scroll sendiri.
      expect(canvasBridgeScript, contains("href.charAt(0) !== '#'"));
    });

    test('does not intercept javascript: hrefs', () {
      expect(canvasBridgeScript, contains("href.indexOf('javascript:') !== 0"));
    });

    test('exposes a selection/interaction mode toggle', () {
      expect(canvasBridgeScript, contains('centauriSetMode'));
      expect(canvasBridgeScript, contains("var mode = 'interact';"));
    });

    test('reports the selected element so the app can show its actions', () {
      // Toolbar aksi (edit dengan AI, hapus) hidup di Flutter; bridge hanya
      // mengirim id + label elemen yang diklik.
      expect(canvasBridgeScript, contains("type: 'select'"));
      expect(canvasBridgeScript, contains('pickedId'));
      expect(canvasBridgeScript, contains('labelOf(pickedId)'));
    });

    test('redirects JS-driven navigation to the host', () {
      // `location.href='x.html'` di handler inline tidak boleh membuat
      // WebView memuat URL yang tidak ada.
      expect(canvasBridgeScript, contains('inlineNavTarget'));
      expect(canvasBridgeScript, contains('patchNavigationApis'));
      expect(canvasBridgeScript, contains("sendToHost({ type: 'navigate'"));
    });
  });

  group('responsive viewport', () {
    test('ensures a viewport meta tag exists', () {
      expect(canvasBridgeScript, contains('ensureViewportMeta'));
      expect(canvasBridgeScript, contains("setAttribute('name', 'viewport')"));
      expect(
        canvasBridgeScript,
        contains("'width=device-width, initial-scale=1'"),
      );
    });

    test('reports document size for export', () {
      expect(canvasBridgeScript, contains('centauriGetSize'));
      expect(canvasBridgeScript, contains("type: 'size'"));
      expect(canvasBridgeScript, contains('scrollWidth'));
      expect(canvasBridgeScript, contains('scrollHeight'));
    });
  });

  group('removed board-era hooks', () {
    test('no longer carries fixed viewport / zoom locking', () {
      // Regresi: board lama mengunci lebar & zoom; kini preview fluid.
      expect(canvasBridgeScript, isNot(contains('window.setViewport')));
      expect(canvasBridgeScript, isNot(contains('window.setZoom')));
      expect(canvasBridgeScript, isNot(contains('nativeZoom')));
      expect(canvasBridgeScript, isNot(contains('lockBrowserZoom')));
      expect(canvasBridgeScript, isNot(contains('collapseEmptyBlocks')));
    });
  });

  group('image fallback', () {
    test('marks broken images without removing src', () {
      // Regresi: dulu onerror memanggil removeAttribute('src') yang memunculkan
      // ikon gambar rusak + teks alt. Sekarang cukup menandai kelas fallback.
      expect(canvasBridgeScript, isNot(contains("removeAttribute('src')")));
      expect(canvasBridgeScript, contains('centauri-fallback'));
    });
  });
}
