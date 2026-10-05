/// How the pager's pages map to the mushaf's: one page per index, or, on
/// a wide screen held sideways, two facing pages per index (a spread).
///
/// Pages before [base] stand alone (the covers); from [base] on, pages go
/// in pairs: [base] and [base] + 1 face each other (the right page first).
class PageSpreads {
  const PageSpreads({
    required this.first,
    required this.base,
    required this.pageCount,
    required this.spread,
  });

  /// The first page the pager shows (0 for a cover page 0).
  final int first;

  /// The first page that opens a spread.
  final int base;
  final int pageCount;
  final bool spread;

  int indexOf(int page) {
    if (!spread || page < base) return page - first;
    return (base - first) + (page - base) ~/ 2;
  }

  /// The pages at [index], right to left.
  List<int> pagesAt(int index) {
    final singles = base - first;
    if (!spread || index < singles) return [index + first];
    final p = base + (index - singles) * 2;
    return [p, if (p + 1 <= pageCount) p + 1];
  }

  /// How many indexes the pager has.
  int get count => indexOf(pageCount) + 1;
}
