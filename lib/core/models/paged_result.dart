class PagedResult<T> {
  const PagedResult({
    required this.items,
    this.total,
    this.page,
    this.pageSize,
  });

  final List<T> items;
  final int? total;
  final int? page;
  final int? pageSize;

  bool get hasMore {
    if (total == null || page == null || pageSize == null) return false;
    return page! * pageSize! < total!;
  }
}
