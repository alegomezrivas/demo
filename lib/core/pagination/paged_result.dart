import 'package:meta/meta.dart';

/// One page of a paginated collection.
@immutable
class PagedResult<T> {
  /// Creates a page.
  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  /// Items of this page.
  final List<T> items;

  /// 1-based page number.
  final int page;

  /// Maximum number of items per page.
  final int pageSize;

  /// Total number of items matching the query across all pages.
  final int total;

  /// Whether another page exists after this one.
  bool get hasMore => page * pageSize < total;
}
