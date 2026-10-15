import 'package:centauri/features/canvas_preview/domain/page.dart';
import 'package:centauri/features/canvas_preview/domain/page_slug.dart';
import 'package:flutter_test/flutter_test.dart';

AppPage _page(String id, String name, {String? slug}) => AppPage(
  id: id,
  name: name,
  slug: slug ?? slugify(name),
  html: '<html><body>$name</body></html>',
);

void main() {
  group('slugify', () {
    test('lowercases and hyphenates spaces', () {
      expect(slugify('Landing Page'), 'landing-page.html');
      expect(slugify('Sign Up'), 'sign-up.html');
    });

    test('strips punctuation and collapses separators', () {
      expect(slugify('Pricing & Plans!'), 'pricing-plans.html');
      expect(slugify('  Home  '), 'home.html');
    });

    test('falls back to page.html when nothing remains', () {
      expect(slugify('!!!'), 'page.html');
      expect(slugify(''), 'page.html');
    });
  });

  group('slugStem', () {
    test('drops the .html extension', () {
      expect(slugStem('landing-page.html'), 'landing-page');
      expect(slugStem('Home.HTML'), 'home');
    });

    test('returns the input when there is no extension', () {
      expect(slugStem('home'), 'home');
    });
  });

  group('uniqueSlug', () {
    test('returns base unchanged when free', () {
      expect(uniqueSlug('home.html', const []), 'home.html');
    });

    test('appends -2, -3 for collisions', () {
      expect(uniqueSlug('home.html', const ['home.html']), 'home-2.html');
      expect(
        uniqueSlug('home.html', const ['home.html', 'home-2.html']),
        'home-3.html',
      );
    });

    test('normalizes a bare stem to .html', () {
      expect(uniqueSlug('Home', const []), 'home.html');
    });
  });

  group('resolveLink', () {
    final pages = [
      _page('page_0', 'Home'),
      _page('page_1', 'Pricing'),
      _page('page_2', 'Sign Up', slug: 'register.html'),
    ];

    test('empty and fragment hrefs are anchors', () {
      expect(resolveLink('', pages).kind, LinkKind.anchor);
      expect(resolveLink('#section', pages).kind, LinkKind.anchor);
    });

    test('absolute and protocol hrefs are external', () {
      for (final href in const [
        'https://example.com',
        'http://example.com',
        '//cdn.example.com/x.png',
        'mailto:hi@example.com',
        'tel:+62812',
        'data:text/plain,hi',
        'javascript:void(0)',
      ]) {
        expect(
          resolveLink(href, pages).kind,
          LinkKind.external,
          reason: '$href harus external',
        );
      }
    });

    test('matches internal pages by slug', () {
      final hit = resolveLink('pricing.html', pages);
      expect(hit.kind, LinkKind.internal);
      expect(hit.pageId, 'page_1');
    });

    test('matches by declared slug even when name differs', () {
      final hit = resolveLink('register.html', pages);
      expect(hit.kind, LinkKind.internal);
      expect(hit.pageId, 'page_2');
    });

    test('matches by page name when slug omitted', () {
      final hit = resolveLink('home.html', pages);
      expect(hit.kind, LinkKind.internal);
      expect(hit.pageId, 'page_0');
    });

    test('strips query, fragment and leading ./ from target', () {
      expect(resolveLink('./pricing.html?v=2#top', pages).pageId, 'page_1');
      expect(resolveLink('/some/dir/pricing.html', pages).pageId, 'page_1');
    });

    test('unknown internal target is reported as unknown', () {
      expect(resolveLink('missing.html', pages).kind, LinkKind.unknown);
    });
  });
}
