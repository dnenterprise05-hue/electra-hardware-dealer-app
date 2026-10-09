import 'package:cloud_firestore/cloud_firestore.dart';
import 'dealer_service.dart';

/// Central pricing configuration.
///
/// Reads from Firestore `pricing_config/global`:
/// - `gstPercent`: GST rate (fallback: 18)
/// - `categoryDiscounts`: {categoryName: discountPct}
/// - `finishDiscounts`: {finishName: discountPct}
///
/// Discount precedence (only ONE applied):
/// 1. Finish-specific discount (highest priority)
/// 2. Category discount
/// 3. Dealer's discountPercentage (fallback)
class PricingService {
  /// Legacy hardcoded fallback — used ONLY when Firestore config
  /// is unavailable. Clearly identified as fallback.
  static const Map<String, double> _fallbackCategoryDiscounts = {
    'Zinc Cabinet Handles': 66,
  };

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

  /// Resolves the effective discount for a category and finish.
  ///
  /// Precedence: finish > category > dealer discountPercentage.
  /// Returns (discountPct, source) where source identifies which
  /// level provided the discount: 'finish', 'category', 'dealer', or 'none'.
  static Future<({double value, String source})>
      discountFor(String? category, String? finish) async {
    await loadConfig();

    // 1. Finish-specific discount (highest priority)
    if (finish != null && finish.isNotEmpty) {
      final finishDiscounts = _configCache?['finishDiscounts']
          as Map<String, dynamic>?;
      final raw = finishDiscounts?[finish];
      if (raw is num && raw >= 0 && raw <= 100) {
        return (value: raw.toDouble(), source: 'finish');
      }
    }

    // 2. Category discount
    if (category != null && category.isNotEmpty) {
      // Firestore config first
      final categoryDiscounts =
          _configCache?['categoryDiscounts']
              as Map<String, dynamic>?;
      final raw = categoryDiscounts?[category];
      if (raw is num && raw >= 0 && raw <= 100) {
        return (value: raw.toDouble(), source: 'category');
      }
      // Legacy hardcoded fallback
      final fallback =
          _fallbackCategoryDiscounts[category];
      if (fallback != null) {
        return (value: fallback, source: 'category-fallback');
      }
    }

    // 3. Dealer discountPercentage fallback
    try {
      final doc = await DealerService.getDealerDoc();
      final raw = doc?.data()?['discountPercentage'];
      if (raw is num) {
        final val = raw.toDouble().clamp(0, 100).toDouble();
        return (value: val, source: 'dealer');
      }
    } catch (_) {}

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
