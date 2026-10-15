import 'package:centauri/features/canvas_preview/domain/page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPage', () {
    test('exposes its identity fields', () {
      const page = AppPage(
        id: 'page_0',
        name: 'Home',
        slug: 'home.html',
        html: '<!DOCTYPE html><html><body>Hi</body></html>',
      );
      expect(page.id, 'page_0');
      expect(page.name, 'Home');
      expect(page.slug, 'home.html');
      expect(page.html, contains('Hi'));
      expect(page.domTree, isNull);
    });

    test('copyWith preserves id and updates the given fields', () {
      const original = AppPage(
        id: 'page_1',
        name: 'Home',
        slug: 'home.html',
        html: '<html></html>',
      );

      final renamed = original.copyWith(name: 'Landing', slug: 'landing.html');
      expect(renamed.id, 'page_1');
      expect(renamed.name, 'Landing');
      expect(renamed.slug, 'landing.html');
      expect(renamed.html, original.html);
    });

    test('copyWith with no arguments keeps every field', () {
      const original = AppPage(
        id: 'p',
        name: 'N',
        slug: 'n.html',
        html: 'x',
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.slug, original.slug);
      expect(copy.html, original.html);
    });
  });
}
