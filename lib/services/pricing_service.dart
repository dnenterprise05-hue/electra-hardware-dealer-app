import 'package:cloud_firestore/cloud_firestore.dart';
import 'dealer_service.dart';

/// Central pricing configuration.
///
/// Simplified dealer-wise category discount pricing:
/// - Each dealer has `categoryDiscounts` map in their Firestore doc
/// - Discount precedence: dealer category > dealer legacy > none
/// - Only ONE discount applied, never combined
///
/// GST read from Firestore `pricing_config/global`:
/// - `gstPercent`: GST rate (fallback: 18, clearly identified)
class PricingService {
  /// Fallback GST when Firestore config unavailable.
  static const double _fallbackGstPercent = 18;

  /// Cached pricing config (null = not loaded or load failed).
  static Map<String, dynamic>? _configCache;
  static bool _configLoaded = false;

  /// Loads pricing config from Firestore. Safe to call multiple times.
  static Future<void> loadConfig() async {
    if (_configLoaded) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pricing_config')
          .doc('global')
          .get();
      _configCache = doc.data();
    } catch (_) {
      _configCache = null;
    }
    _configLoaded = true;
  }

  /// Forces reload on next call (e.g. after admin changes).
  static void invalidateCache() {
    _configLoaded = false;
    _configCache = null;
  }

  /// GST percentage. Returns config value, or fallback 18 with
  /// [isFallback] set to true via the returned record.
  static Future<({double value, bool isFallback})>
      gstPercent() async {
    await loadConfig();
    final raw = _configCache?['gstPercent'];
    if (raw is num && raw >= 0 && raw <= 100) {
      return (value: raw.toDouble(), isFallback: false);
    }
    return (value: _fallbackGstPercent, isFallback: true);
  }

  /// Resolves the effective discount for a category.
  ///
  /// Precedence (only ONE applied, never combined):
  /// 1. Dealer's categoryDiscounts[category] (per-dealer, per-category)
  /// 2. Dealer's legacy discountPercentage (backward compat)
  /// 3. No discount (0%)
  ///
  /// Returns (discountPct, source) where source is:
  /// 'dealer-category', 'dealer-legacy', or 'none'.
  static Future<({double value, String source})>
      discountFor(String? category, String? finish) async {
    // Note: finish parameter kept for API compat, not used in
    // simplified pricing (dealer category discounts only).

    // 1. Dealer's per-category discount (highest priority)
    if (category != null && category.isNotEmpty) {
      try {
        final doc = await DealerService.getDealerDoc();
        final data = doc?.data();
        final categoryDiscounts =
            data?['categoryDiscounts'] as Map<String, dynamic>?;
        final raw = categoryDiscounts?[category];
        if (raw is num && raw >= 0 && raw <= 100) {
          return (
            value: raw.toDouble(),
            source: 'dealer-category'
          );
        }
      } catch (_) {}
    }

    // 2. Legacy dealer discountPercentage fallback
    try {
      final doc = await DealerService.getDealerDoc();
      final raw = doc?.data()?['discountPercentage'];
      if (raw is num) {
        final val = raw.toDouble().clamp(0, 100).toDouble();
        return (value: val, source: 'dealer-legacy');
      }
    } catch (_) {}

    // 3. No discount configured
    return (value: 0.0, source: 'none');
  }

  /// Legacy: resolves discount for category only (no finish).
  /// Prefer [discountFor] with finish parameter.
  static Future<double> discountForCategory(
      String? category) async {
    final result = await discountFor(category, null);
    return result.value;
  }

  /// Dealer price per PCS: MRP minus single discount, rounded.
  static double dealerPrice(double mrp, double discountPct) {
    final raw = mrp - (mrp * discountPct / 100);
    return raw.roundToDouble();
  }

  /// GST on the taxable amount, rounded to nearest rupee.
  static double gstOn(double taxable, double gstPct) {
    return (taxable * gstPct / 100).roundToDouble();
  }
}
