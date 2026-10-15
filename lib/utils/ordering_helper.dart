/// Shared ordering rules for categories, sizes and finishes.
/// Mirrors the Admin Panel's OrderingHelper for consistent display.
class DealerOrdering {
  /// Fixed order for the 5 standard categories.
  static const List<String> standardCategoryOrder = [
    'Zinc Cabinet Handles',
    'Aluminium Cabinet & Door Handles',
    'Zinc Mortise Handles',
    'Kadi, Knobs & Door Stoppers',
    'Commercial Cabinet Handles',
  ];

  /// Sorts category names: 5 standard first (fixed order,
  /// case-insensitive), then custom alphabetically.
  static List<String> sortCategoryNames(List<String> names) {
    final sorted = List<String>.from(names);
    sorted.sort((a, b) {
      final ia = _standardIndex(a);
      final ib = _standardIndex(b);
      if (ia != -1 && ib != -1) return ia.compareTo(ib);
      if (ia != -1) return -1;
      if (ib != -1) return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return sorted;
  }

  static int _standardIndex(String name) {
    final n = name.trim().toLowerCase();
    for (int i = 0; i < standardCategoryOrder.length; i++) {
      if (standardCategoryOrder[i].toLowerCase() == n) return i;
    }
    return -1;
  }

  /// Extracts numeric value from size label like "96 MM".
  static double? sizeNumber(String size) {
    final match =
        RegExp(r'(\d+(\.\d+)?)').firstMatch(size);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  /// Returns true for Mortise handle categories.
  static bool isMortiseCategory(String? category) {
    if (category == null) return false;
    return category.toLowerCase().contains('mortise');
  }

  /// Fixed order for Mortise size/type variants:
  /// 0 = ROSE FULL SET, 1 = 8" PLATE FULL SET, 2 = 10" PLATE FULL SET.
  static int mortiseSizeOrder(String size) {
    final s = size.toLowerCase();
    final hasFullSet = s.contains('full set');
    if (s.contains('rose') && hasFullSet) return 0;
    if ((s.contains('8"') ||
            s.contains('8 inch') ||
            s.contains('8in') ||
            RegExp(r'\b8\b').hasMatch(s)) &&
        s.contains('plate') &&
        hasFullSet) {
      return 1;
    }
    if ((s.contains('10"') ||
            s.contains('10 inch') ||
            s.contains('10in') ||
            RegExp(r'\b10\b').hasMatch(s)) &&
        s.contains('plate') &&
        hasFullSet) {
      return 2;
    }
    return 999;
  }

  /// Sorts sizes for a category. Mortise uses fixed ROSE → 8" → 10"
  /// sequence; others use numeric ascending.
  static List<String> sortSizesForCategory(
      List<String> sizes, String? category) {
    if (!isMortiseCategory(category)) {
      return sortSizes(sizes);
    }
    final sorted = List<String>.from(sizes);
    sorted.sort((a, b) {
      final ra = mortiseSizeOrder(a);
      final rb = mortiseSizeOrder(b);
      if (ra != rb) return ra.compareTo(rb);
      final na = sizeNumber(a);
      final nb = sizeNumber(b);
      if (na != null && nb != null) {
        return na.compareTo(nb);
      }
      if (na != null) return -1;
      if (nb != null) return 1;
      return 0;
    });
    return sorted;
  }

  /// Sorts sizes numerically ascending; non-numeric go last.
  static List<String> sortSizes(List<String> sizes) {
    final sorted = List<String>.from(sizes);
    sorted.sort((a, b) {
      final na = sizeNumber(a);
      final nb = sizeNumber(b);
      if (na != null && nb != null) {
        return na.compareTo(nb);
      }
      if (na != null) return -1;
      if (nb != null) return 1;
      return 0;
    });
    return sorted;
  }

  /// Sorts finishes: CP (+combinations) → SATIN → ANTIQUE → rest.
  /// Names are never modified.
  static List<String> sortFinishes(List<String> finishes) {
    final sorted = List<String>.from(finishes);
    sorted.sort((a, b) {
      final ra = _finishRank(a);
      final rb = _finishRank(b);
      if (ra != rb) return ra.compareTo(rb);
      return 0;
    });
    return sorted;
  }

  static int _finishRank(String finish) {
    final f = finish.trim().toUpperCase();
    if (f == 'CP' || RegExp(r'^CP[\s+\/\-]').hasMatch(f)) {
      return 0;
    }
    if (f == 'SATIN') return 1;
    if (f == 'ANTIQUE') return 2;
    return 1000;
  }
}
