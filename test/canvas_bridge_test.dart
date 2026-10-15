import 'package:centauri/features/canvas_preview/data/services/canvas_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('injectBridge', () {
    const html = '<!DOCTYPE html><html><body><div id="a">Hi</div></body></html>';

    test('menyuntikkan script bridge sebelum </body>', () {
      final out = injectBridge(html, nativeZoom: false);
      final bodyClose = out.lastIndexOf('</body>');
      final scriptIndex = out.indexOf('id="centauri-bridge"');
      expect(scriptIndex, greaterThan(0));
      expect(scriptIndex, lessThan(bodyClose));
      // Dokumen asli tidak hilang.
      expect(out, contains('<div id="a">Hi</div>'));
    });

    test('menandai native zoom sesuai argumen', () {
      expect(injectBridge(html, nativeZoom: true),
          contains('window.__centauriNativeZoom = true'));
      expect(injectBridge(html, nativeZoom: false),
          contains('window.__centauriNativeZoom = false'));
    });

    test('mengekspos API window yang dipakai Dart', () {
      final out = injectBridge(html, nativeZoom: true);
      for (final fn in const [
        'window.centauriSelect',
        'window.centauriHover',
        'window.centauriInspect',
        'window.centauriApplyStyle',
        'window.centauriMoveResize',
        'window.centauriGetHtml',
        'window.centauriExportPng',
        'window.setViewport',
        'window.setZoom',
      ]) {
        expect(out, contains(fn), reason: 'API $fn harus ada');
      }
    });

    test('fallback ke </html> bila tidak ada </body>', () {
      const fragment = '<div>x</div>';
      final out = injectBridge(fragment, nativeZoom: false);
      expect(out, contains('id="centauri-bridge"'));
      expect(out, contains('<div>x</div>'));
    });

    test('hanya menyuntik sekali (idempoten terhadap id uniknya)', () {
      final out = injectBridge(html, nativeZoom: false);
      // Satu script bridge untuk satu dokumen.
      expect('id="centauri-bridge"'.allMatches(out).length, 1);
    });

    test('fallback gambar TIDAK menghapus src (anti alt/ikon rusak)', () {
      // Regresi: dulu onerror memanggil removeAttribute('src') yang memunculkan
      // ikon gambar rusak + teks alt. Sekarang cukup menandai kelas fallback.
      expect(canvasBridgeScript, isNot(contains("removeAttribute('src')")));
      expect(canvasBridgeScript, contains('centauri-fallback'));
    });

    test('mengunci zoom bawaan browser agar isi frame tetap fix', () {
      // Regresi: pinch/Ctrl+scroll di atas frame men-zoom isi halaman
      // (double-zoom) karena WebView2/Edge menangani gestur secara native.
      // Shell harus menonaktifkan pinch-zoom (touch-action) + Ctrl zoom.
      expect(canvasBridgeScript, contains('centauri-zoom-lock'));
      expect(canvasBridgeScript, contains('touch-action:pan-x pan-y'));
      expect(canvasBridgeScript, contains('lockBrowserZoom();'));
    });

    test('melipat blok kosong raksasa agar frame tanpa white space', () {
      // Regresi: section/div >= 480px tanpa isi (spacer, min-height berlebih)
      // membuat frame terlihat punya white space besar. Shell melipatnya
      // otomatis sebelum melaporkan tinggi konten.
      expect(canvasBridgeScript, contains('collapseEmptyBlocks'));
      expect(canvasBridgeScript, contains('collapseEmptyBlocks();'));
    });
  });
}
