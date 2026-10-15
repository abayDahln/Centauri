import 'package:centauri/features/canvas_preview/data/services/canvas_webview_service.dart';
import 'package:centauri/features/canvas_preview/domain/page.dart';
import 'package:centauri/features/canvas_preview/domain/page_slug.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aksi yang diambil app saat user mengklik sebuah link di preview.
enum NavAction { openPage, launchExternal, ignoreAnchor, warnUnknown }

/// Cermin dari `PagePreview._onNavigate`: parse event `navigate` dari JS lalu
/// putuskan aksinya. Diekstrak di sini agar kontraknya bisa diuji tanpa WebView.
NavAction decide(String? href, List<AppPage> pages) {
  final link = resolveLink(href ?? '', pages);
  switch (link.kind) {
    case LinkKind.internal:
      return NavAction.openPage;
    case LinkKind.external:
      return NavAction.launchExternal;
    case LinkKind.anchor:
      return NavAction.ignoreAnchor;
    case LinkKind.unknown:
      return NavAction.warnUnknown;
  }
}

AppPage _page(String id, String name, {String? slug}) => AppPage(
  id: id,
  name: name,
  slug: slug ?? slugify(name),
  html: '<html><body>$name</body></html>',
);

void main() {
  final pages = [
    _page('page_0', 'Home'),
    _page('page_1', 'Pricing'),
    _page('page_2', 'Register', slug: 'signup.html'),
  ];

  group('navigate event parsing', () {
    test('extracts the href from the JS bridge payload', () {
      final event = CanvasSelectEvent.tryParse({
        'type': 'navigate',
        'href': 'pricing.html',
      });
      expect(event!.type, 'navigate');
      expect(event.href, 'pricing.html');
    });
  });

  group('navigation decisions', () {
    test('internal link loads the matching page', () {
      final event = CanvasSelectEvent.tryParse({
        'type': 'navigate',
        'href': 'pricing.html',
      })!;
      final link = resolveLink(event.href!, pages);
      expect(decide(event.href, pages), NavAction.openPage);
      expect(link.pageId, 'page_1');
    });

    test('declared slug resolves even when it differs from the name', () {
      expect(decide('signup.html', pages), NavAction.openPage);
      expect(resolveLink('signup.html', pages).pageId, 'page_2');
    });

    test('external link is launched outside the app', () {
      expect(decide('https://flutter.dev', pages), NavAction.launchExternal);
      expect(decide('mailto:hi@centauri.app', pages), NavAction.launchExternal);
    });

    test('in-page anchor is left to the browser', () {
      expect(decide('#pricing', pages), NavAction.ignoreAnchor);
    });

    test('unresolved internal target warns the user', () {
      expect(decide('missing.html', pages), NavAction.warnUnknown);
    });

    test('null href is treated as an anchor (no navigation)', () {
      expect(decide(null, pages), NavAction.ignoreAnchor);
    });
  });
}
