import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  static final CartService instance = CartService();

  static final List<CartItem> cartItems = [];

  static void addToCart(CartItem item) {
    final index = cartItems.indexWhere(
      (e) =>
          e.modelNo == item.modelNo &&
          e.finish == item.finish,
    );

    if (index != -1) {
      final existing = cartItems[index];

      final updatedQty =
          Map<String, int>.from(existing.quantities);

      item.quantities.forEach((size, qty) {
        if (qty > 0) {
          updatedQty[size] =
              (updatedQty[size] ?? 0) + qty;
        }
      });

      cartItems[index] = CartItem(
        modelNo: existing.modelNo,
        imageUrl: existing.imageUrl,
        finish: existing.finish,
        quantities: updatedQty,
      );
    } else {
      cartItems.add(item);
    }

    instance.notifyListeners();
  }

  static void removeItem(int index) {
    cartItems.removeAt(index);
    instance.notifyListeners();
  }

  static void clearCart() {
    cartItems.clear();
    instance.notifyListeners();
  }

  static int get totalItems {
    return cartItems.length;
  }

  static CartItem? findCartItem({
    required String modelNo,
    required String finish,
    required Map<String, int> quantities,
  }) {
    try {
      return cartItems.firstWhere((item) {
        if (item.modelNo != modelNo) return false;
        if (item.finish != finish) return false;

        for (final size in quantities.keys) {
          if ((quantities[size] ?? 0) > 0 &&
              (item.quantities[size] ?? 0) > 0) {
            return true;
          }
        }

        return false;
      });
    } catch (e) {
      return null;
    }
  }
}