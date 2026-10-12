import 'package:demo/core/pagination/paged_result.dart';
import 'package:flutter_test/flutter_test.dart';

PagedResult<int> page(int page, int size, int total) =>
    PagedResult(items: const [], page: page, pageSize: size, total: total);

void main() {
  group('PagedResult.hasMore', () {
    test('is true while items remain after this page', () {
      expect(page(1, 10, 25).hasMore, isTrue);
      expect(page(2, 10, 25).hasMore, isTrue);
    });

    test('is false on the last page, including an exact boundary', () {
      expect(page(3, 10, 25).hasMore, isFalse);
      expect(page(2, 10, 20).hasMore, isFalse);
    });

    test('is false for an empty collection', () {
      expect(page(1, 10, 0).hasMore, isFalse);
    });
  });
}
