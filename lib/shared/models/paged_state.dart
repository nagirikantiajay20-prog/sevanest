/// Cursor-paginated list state (AGENTS §23). Follows backend cursor semantics, not page numbers.
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<T> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => nextCursor != null;
  bool get canLoadMore => hasMore && !isLoadingMore;

  PagedState<T> loadingMore() =>
      PagedState(items: items, nextCursor: nextCursor, isLoadingMore: true);

  PagedState<T> appended(List<T> page, String? cursor) =>
      PagedState(items: [...items, ...page], nextCursor: cursor);

  PagedState<T> failedMore(Object error) =>
      PagedState(items: items, nextCursor: nextCursor, loadMoreError: error);
}
