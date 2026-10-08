import 'package:cloud_firestore/cloud_firestore.dart';
import 'dealer_service.dart';

/// Central pricing configuration.
///
/// Category-wise dealer discounts. Categories not listed here fall back
/// to the dealer's own discountPercentage from Firestore.
class PricingService {
  /// Category name -> discount percentage.
  /// Keys must match the exact Firestore category display names.
  static const Map<String, double> categoryDiscounts = {
    'Zinc Cabinet Handles': 66,
  };

  /// GST percentage applied on the taxable amount.
  static const double gstPercent = 18;

  /// Resolves the effective discount for a category.
  /// Category-specific discount wins; otherwise the dealer's
  /// discountPercentage; 0 when neither is available.
  static Future<double> discountFor(String? category) async {
    final catDiscount = category != null
        ? categoryDiscounts[category]
        : null;
    if (catDiscount != null) return catDiscount;

    try {
      final doc = await DealerService.getDealerDoc();
      final raw = doc?.data()?['discountPercentage'];
      if (raw is num) {
        return raw.toDouble().clamp(0, 100);
      }
    } catch (_) {}
    return 0;
  }

  /// Dealer price per PCS: MRP minus discount, rounded to nearest rupee.
  static double dealerPrice(double mrp, double discountPct) {
    final raw = mrp - (mrp * discountPct / 100);
    return raw.roundToDouble();
  }

  /// GST on the taxable amount, rounded to nearest rupee.
  static double gstOn(double taxable) {
    return (taxable * gstPercent / 100).roundToDouble();
  }
}
