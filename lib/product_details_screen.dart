import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/pressable.dart';
import 'models/cart_item.dart';
import 'services/cart_service.dart';
import 'services/dealer_service.dart';
import 'services/pricing_service.dart';
import 'cart_screen.dart';
import 'services/favourite_service.dart';

/// Product Details — luxury showroom theme.
///
/// UI-only redesign. Product data, finish/size/qty/MOQ logic, cart
/// behavior, favourites and navigation are unchanged from the previous
/// implementation. Product photos are displayed exactly as provided.
class ProductDetailsScreen extends StatefulWidget {
  final String modelNo;
  final String imageUrl;

  /// Full Firestore product document (may contain size-wise MRP).
  final Map<String, dynamic>? productData;

  /// Product category (for category-wise discount).
  final String? category;

  const ProductDetailsScreen({
    super.key,
    required this.modelNo,
    required this.imageUrl,
    this.productData,
    this.category,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  // ---- Warm champagne palette (matches locked theme) ----
  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _goldDeep = Color(0xFF8A6A2F);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  String selectedFinish = "CP";
  CartItem? existingCartItem;

  final List<String> finishes = [
    "CP",
    "SATIN",
    "ANTIQUE",
    "GOLD",
    "ROSEGOLD",
    "Z.BLACK",
    "B.SATIN",
  ];

  final Map<String, int> qty = {
    "96 MM": 0,
    "160 MM": 0,
    "224 MM": 0,
    "288 MM": 0,
  };

  final Map<String, int> moq = {
    "96 MM": 48,
    "160 MM": 32,
    "224 MM": 12,
    "288 MM": 10,
  };

  final Map<String, int> boxQty = {
    "96 MM": 24,
    "160 MM": 16,
    "224 MM": 12,
    "288 MM": 10,
  };

  /// EL 231 MRP per PCS by finish and size (real prices).
  /// Finishes not listed here use the "remaining colours" rates.
  static const Map<String, Map<String, double>>
      _el231Mrp = {
    'CP': {
      '96 MM': 190,
      '160 MM': 310,
      '224 MM': 425,
      '288 MM': 590,
    },
    'SATIN': {
      '96 MM': 210,
      '160 MM': 350,
      '224 MM': 480,
      '288 MM': 650,
    },
    'ANTIQUE': {
      '96 MM': 210,
      '160 MM': 350,
      '224 MM': 480,
      '288 MM': 650,
    },
    '_OTHERS': {
      '96 MM': 235,
      '160 MM': 395,
      '224 MM': 540,
      '288 MM': 720,
    },
  };

  /// Fixed size-card text colour (CP appearance) for all finishes.
  static const Color _finishColor = Color(0xFFF2F2F2);

  /// MRP lookup: finish + size -> MRP per PCS.
  /// Falls back to Firestore data, then EL 231 table.
  double? _mrpFor(String finish, String size) {
    // 1. Firestore size-wise MRP (if present).
    final fs = _mrpFs[size];
    if (fs != null) return fs;
    // 2. EL 231 built-in table (only for EL 231).
    if (widget.modelNo.trim().toUpperCase() ==
        'EL 231') {
      final byFinish =
          _el231Mrp[finish] ?? _el231Mrp['_OTHERS'];
      return byFinish?[size];
    }
    return null;
  }

  /// Size-wise MRP from Firestore (null when not available).
  final Map<String, double> _mrpFs = {};

  /// Dealer discount percentage (0 when missing).
  double _discountPct = 0;
  bool _pricingLoaded = false;

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Whole-rupee formatter for final dealer prices.
  static final _inr0 = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  /// Reads size-wise MRP from the product document and the dealer's
  /// discount percentage. Missing data is handled gracefully.
  Future<void> _loadPricing() async {
    // MRP per size from product document.
    final data = widget.productData;
    if (data != null) {
      final sizes = data['sizes'];
      if (sizes is List) {
        for (final s in sizes) {
          if (s is Map) {
            final name = (s['size'] ?? '').toString();
            final raw = s['mrp'];
            if (name.isNotEmpty && raw is num) {
              _mrpFs[name] = raw.toDouble();
            }
          }
        }
      }
      // Also support flat map: {"96 MM": 100, ...}
      final mrps = data['mrps'];
      if (mrps is Map) {
        mrps.forEach((k, v) {
          if (v is num) _mrpFs[k.toString()] = v.toDouble();
        });
      }
    }

    // Dealer discount: category-specific wins, else dealer's own.
    _discountPct =
        await PricingService.discountFor(widget.category);

    if (mounted) setState(() => _pricingLoaded = true);
  }

  /// Dealer price per PCS: MRP minus discount, rounded to nearest
  /// rupee. Null when MRP is unavailable.
  double? _dealerPrice(String finish, String size) {
    final mrp = _mrpFor(finish, size);
    if (mrp == null) return null;
    return PricingService.dealerPrice(mrp, _discountPct);
  }

  /// Compact price display for a size row.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // SAME luxury showroom background as Dashboard / Place Order.
          Image.asset(
            'assets/login_background.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.68),
                  Colors.black.withValues(alpha: 0.42),
                  Colors.black.withValues(alpha: 0.60),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ================= PREMIUM HEADER =================
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: _ivory,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "PRODUCT DETAILS",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ivory,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CartScreen(),
                            ),
                          );
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 14, left: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: _gold,
                                size: 22,
                              ),
                              const SizedBox(width: 5),
                              AnimatedBuilder(
                                animation:
                                    CartService.instance,
                                builder: (context, child) {
                                  return Text(
                                    "${CartService.totalItems}",
                                    style: const TextStyle(
                                      color: _ivory,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= SCROLLABLE CONTENT =================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        24, 10, 24, 24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ---------- MODEL NUMBER ----------
                        Center(
                          child: Column(
                            children: [
                              Text(
                                widget.modelNo,
                                style: const TextStyle(
                                  color: _ivory,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient:
                                      const LinearGradient(
                                    colors: [
                                      _goldDeep,
                                      _goldBright
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                          2),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ---------- PRODUCT PHOTO ----------
                        // Photo displayed exactly as provided.
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(
                                          16),
                                  border: Border.all(
                                    color: _gold.withValues(
                                        alpha: 0.4),
                                  ),
                                ),
                                // Dark glass display case behind
                                // the untouched product photo.
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(
                                          15),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(
                                            sigmaX: 2.5,
                                            sigmaY: 2.5),
                                    child: Container(
                                      color: Colors.black
                                          .withValues(
                                              alpha:
                                                  0.35),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    15),
                                        child:
                                            Image.network(
                                          widget.imageUrl,
                                          fit:
                                              BoxFit.contain,
                                          errorBuilder:
                                              (context,
                                                  error,
                                                  stackTrace) {
                                            return const Icon(
                                              Icons.image,
                                              size: 80,
                                              color:
                                                  _muted,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: AnimatedBuilder(
                                  animation: FavouriteService
                                      .instance,
                                  builder: (context, child) {
                                    final fav =
                                        FavouriteService
                                            .instance
                                            .isFavourite(
                                      widget.modelNo,
                                    );
                                    return Pressable(
                                      onTap: () {
                                        FavouriteService
                                            .instance
                                            .toggleFavourite(
                                          modelNo:
                                              widget.modelNo,
                                          imageUrl: widget
                                              .imageUrl,
                                        );
                                      },
                                      child: Container(
                                        padding:
                                            const EdgeInsets
                                                .all(8),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.black
                                              .withValues(
                                                  alpha:
                                                      0.55),
                                          shape:
                                              BoxShape.circle,
                                          border: Border.all(
                                            color: _gold
                                                .withValues(
                                                    alpha:
                                                        0.5),
                                          ),
                                        ),
                                        child: Icon(
                                          fav
                                              ? Icons.favorite
                                              : Icons
                                                  .favorite_border,
                                          color: fav
                                              ? _goldBright
                                              : _gold,
                                          size: 22,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ---------- COLOUR ----------
                        const Text(
                          "COLOUR",
                          style: TextStyle(
                            color: _ivory,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              finishes.map((finish) {
                            final selected =
                                finish == selectedFinish;
                            // Glass colour chip — same ~10%
                            // frost as the size panels.
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                        10),
                                border: Border.all(
                                  color: _gold.withValues(
                                      alpha: selected
                                          ? 0.9
                                          : 0.35),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                        10),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 2.5,
                                      sigmaY: 2.5),
                                  child: Container(
                                    color: selected
                                        ? _gold.withValues(
                                            alpha: 0.85)
                                        : Colors.black
                                            .withValues(
                                                alpha:
                                                    0.10),
                                    child: Pressable(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  10),
                                      onTap: () {
                                        setState(() {
                                          selectedFinish =
                                              finish;
                                        });
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                        child: Text(
                                          finish,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.black
                                                : _ivory,
                                            fontWeight:
                                                selected
                                                    ? FontWeight
                                                        .w700
                                                    : FontWeight
                                                        .w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 26),

                        // ---------- SIZES + QUANTITY ----------
                        ...qty.keys.map((size) {
                          return _sizeCard(size);
                        }),
                        const SizedBox(height: 20),

                        // ---------- ADD TO CART ----------
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _handleAddToCart(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: Colors.black,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        14),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                                Icons.shopping_cart,
                                size: 20),
                            label: const Text(
                              "ADD TO CART",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gold-outlined circular quantity button.
  /// Premium luxury size card.
  /// Hierarchy: size + pricing (top), quantity (middle), box/moq (bottom).
  /// Premium luxury size card.
  /// Hierarchy: size + pricing (top), quantity (middle), box/moq (bottom).
  Widget _sizeCard(String size) {
    final mrp = _mrpFor(selectedFinish, size);
    final price = _dealerPrice(selectedFinish, size);
    final hasDiscount = _discountPct > 0 && price != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.25, 1.0],
              ),
            ),
            child: Column(
              children: [
                // Subtle champagne accent line at the top.
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _gold.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      18, 12, 18, 14),
                  child: Column(
                    children: [
                      // ---- TOP: size (left) + pricing (right) ----
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Size label.
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(
                                      top: 2),
                              child: Text(
                                size,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: _finishColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          // Pricing block (right-aligned).
                          // Row 1: MRP + OFF badge.
                          // Row 2: dealer price.
                          if (mrp != null &&
                              price != null)
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    // MRP with clear
                                    // strike-through.
                                    Text(
                                      'MRP ${_inr0.format(mrp)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _finishColor
                                            .withValues(
                                                alpha:
                                                    0.85),
                                        decoration:
                                            TextDecoration
                                                .lineThrough,
                                        decorationColor:
                                            _muted,
                                        decorationThickness:
                                            1.2,
                                      ),
                                    ),
                                    if (hasDiscount) ...[
                                      const SizedBox(
                                          width: 6),
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                                    horizontal:
                                                        6,
                                                    vertical:
                                                        1),
                                        decoration:
                                            BoxDecoration(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      5),
                                          border:
                                              Border
                                                  .all(
                                            color: _gold
                                                .withValues(
                                                    alpha:
                                                        0.5),
                                          ),
                                        ),
                                        child: Text(
                                          '${_discountPct.toStringAsFixed(_discountPct % 1 == 0 ? 0 : 1)}% OFF',
                                          style:
                                              TextStyle(
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            color:
                                                _finishColor,
                                            letterSpacing:
                                                0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                // Dealer price (strongest).
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _inr0
                                            .format(
                                                price),
                                        style:
                                            TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          color:
                                              _finishColor,
                                          letterSpacing:
                                              0.3,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / PCS',
                                        style:
                                            TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight
                                                  .w500,
                                          color:
                                              _finishColor
                                                  .withValues(
                                                      alpha:
                                                          0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ---- MIDDLE: quantity controls ----
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _qtyButton(
                            icon: Icons.remove,
                            iconColor: _finishColor,
                            onPressed: () {
                              setState(() {
                                if (qty[size] == 0) {
                                  return;
                                }
                                if (qty[size] ==
                                    moq[size]) {
                                  qty[size] = 0;
                                } else {
                                  qty[size] =
                                      qty[size]! -
                                          boxQty[
                                              size]!;
                                }
                              });
                            },
                          ),
                          Text(
                            qty[size].toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w700,
                              color: _finishColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          _qtyButton(
                            icon: Icons.add,
                            iconColor: _finishColor,
                            onPressed: () {
                              setState(() {
                                if (qty[size] == 0) {
                                  qty[size] =
                                      moq[size]!;
                                } else {
                                  qty[size] =
                                      qty[size]! +
                                          boxQty[
                                              size]!;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ---- BOTTOM: box qty | MOQ ----
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: _gold.withValues(
                                  alpha: 0.18),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'BOX QTY ${boxQty[size]} PCS',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _finishColor,
                                  fontWeight:
                                      FontWeight.w500,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 14,
                              color: _gold.withValues(
                                  alpha: 0.35),
                            ),
                            Expanded(
                              child: Text(
                                'MOQ ${moq[size]} PCS',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _finishColor,
                                  fontWeight:
                                      FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  static Widget _qtyButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    final ic = iconColor ?? _gold;
    return Pressable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _gold.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Icon(icon, color: ic, size: 18),
      ),
    );
  }

  /// Add-to-cart flow — logic unchanged from the previous implementation.
  void _handleAddToCart(BuildContext context) {
    final selectedSizes =
        qty.entries.where((e) => e.value > 0).toList();

    if (selectedSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select quantity."),
        ),
      );
      return;
    }

    final existing = CartService.findCartItem(
      modelNo: widget.modelNo,
      finish: selectedFinish,
      quantities: qty,
    );

    if (existing != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141210),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _gold.withValues(alpha: 0.4),
            ),
          ),
          title: const Text(
            "Already in Cart",
            style: TextStyle(color: _ivory),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                "Finish : ${existing.finish}",
                style:
                    const TextStyle(color: _ivorySoft),
              ),
              const SizedBox(height: 10),
              ...existing.quantities.entries
                  .where((e) => e.value > 0)
                  .map(
                    (e) => Text(
                      "${e.key} → ${e.value} PCS",
                      style: const TextStyle(
                          color: _ivorySoft),
                    ),
                  ),
              const SizedBox(height: 15),
              const Text(
                "Adding again will increase the quantity.",
                style: TextStyle(color: _muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "CANCEL",
                style: TextStyle(color: _muted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final prices = <String, double>{};
                final mrps = <String, double>{};
                qty.forEach((size, q) {
                  if (q > 0) {
                    final mrp =
                        _mrpFor(selectedFinish, size);
                    final price = _dealerPrice(
                        selectedFinish, size);
                    if (mrp != null) mrps[size] = mrp;
                    if (price != null) prices[size] = price;
                  }
                });
                CartService.addToCart(
                  CartItem(
                    modelNo: widget.modelNo,
                    imageUrl: widget.imageUrl,
                    finish: selectedFinish,
                    quantities: Map.from(qty),
                    prices: prices,
                    mrps: mrps,
                  ),
                );
                setState(() {
                  qty.updateAll((key, value) => 0);
                });
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content:
                        Text("Product added to cart"),
                  ),
                );
                Navigator.pop(this.context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              child: const Text("ADD ANYWAY"),
            ),
          ],
        ),
      );
      return;
    }

    // Per-size dealer prices for the estimate.
    final prices = <String, double>{};
    final mrps = <String, double>{};
    qty.forEach((size, q) {
      if (q > 0) {
        final mrp = _mrpFor(selectedFinish, size);
        final price =
            _dealerPrice(selectedFinish, size);
        if (mrp != null) mrps[size] = mrp;
        if (price != null) prices[size] = price;
      }
    });

    CartService.addToCart(
      CartItem(
        modelNo: widget.modelNo,
        imageUrl: widget.imageUrl,
        finish: selectedFinish,
        quantities: Map.from(qty),
        prices: prices,
        mrps: mrps,
      ),
    );

    setState(() {
      qty.updateAll((key, value) => 0);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Product added to cart"),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }
}
