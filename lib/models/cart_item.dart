class CartItem {
  final String modelNo;
  final String imageUrl;
  final String finish;
  final Map<String, int> quantities;

  CartItem({
    required this.modelNo,
    required this.imageUrl,
    required this.finish,
    required this.quantities,
  });

  int get totalQty {
    int total = 0;

    for (final qty in quantities.values) {
      total += qty;
    }

    return total;
  }
}