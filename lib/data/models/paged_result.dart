/// Wrapper kết quả phân trang — dùng cho mọi endpoint trả danh sách.
///
/// Backend trả JSON dạng:
/// {
///   "items": [...],
///   "totalCount": 42,
///   "page": 1,
///   "pageSize": 20
/// }
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages => pageSize == 0 ? 1 : (totalCount / pageSize).ceil();
  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawItems = (json['items'] as List<dynamic>? ?? []);
    return PagedResult(
      items: rawItems.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }
}
