class CartItem {
  final String modelNo;
  final String imageUrl;
  final String finish;
  final Map<String, int> quantities;

  /// Dealer price per size (null when MRP unavailable).
  final Map<String, double> prices;

  /// MRP per size (null when unavailable).
  final Map<String, double> mrps;

  CartItem({
    required this.modelNo,
    required this.imageUrl,
    required this.finish,
    required this.quantities,
    this.prices = const {},
    this.mrps = const {},
  });

  int get totalQty {
    int total = 0;

    for (final qty in quantities.values) {
      total += qty;
    }

    return total;
  }

  /// Estimated amount using dealer prices (0 when no pricing).
  double get estimateTotal {
    double total = 0;
    quantities.forEach((size, qty) {
      final price = prices[size];
      if (price != null) total += price * qty;
    });
    // Round to 2 decimals.
    return double.parse(total.toStringAsFixed(2));
  }

  /// True when at least one size has pricing.
  bool get hasPricing => prices.isNotEmpty;
}