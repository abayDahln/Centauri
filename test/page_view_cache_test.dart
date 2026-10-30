import 'package:centauri/features/canvas_preview/presentation/widgets/page_view_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageViewCache', () {
    test('menyimpan dan mengambil entri', () {
      final cache = PageViewCache<String>();
      cache.store('a', 'A');

      expect(cache.contains('a'), isTrue);
      expect(cache['a'], 'A');
      expect(cache.length, 1);
    });

    test('membuang entri paling lama saat melebihi batas', () {
      final cache = PageViewCache<String>(maxEntries: 2);
      cache.store('a', 'A');
      cache.store('b', 'B');
      final evicted = cache.store('c', 'C');

      expect(evicted, ['A']);
      expect(cache.ids, ['b', 'c']);
    });

    test('entri yang dipakai ulang naik ke urutan terbaru', () {
      final cache = PageViewCache<String>(maxEntries: 2);
      cache.store('a', 'A');
      cache.store('b', 'B');
      cache.touch('a');

      final evicted = cache.store('c', 'C');

      expect(evicted, ['B']);
      expect(cache.ids, ['a', 'c']);
    });

    test('halaman yang dilindungi tidak pernah dibuang', () {
      final cache = PageViewCache<String>(maxEntries: 2);
      cache.store('a', 'A');
      cache.store('b', 'B');

      // 'a' adalah halaman tujuan / yang sedang tampil.
      final evicted = cache.store('c', 'C', keep: ['a']);

      expect(evicted, ['B']);
      expect(cache.contains('a'), isTrue);
      expect(cache.contains('c'), isTrue);
    });

    test('menyimpan ulang id yang sama tidak menambah entri', () {
      final cache = PageViewCache<String>(maxEntries: 2);
      cache.store('a', 'A');
      cache.store('a', 'A2');

      expect(cache.length, 1);
      expect(cache['a'], 'A2');
    });

    test('remove dan clear mengosongkan cache', () {
      final cache = PageViewCache<String>();
      cache.store('a', 'A');
      cache.store('b', 'B');

      expect(cache.remove('a'), 'A');
      expect(cache.contains('a'), isFalse);
      expect(cache.clear(), ['B']);
      expect(cache.length, 0);
    });
  });
}
