import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  /// Used as initial data; live updates come from [productId] stream.
  final Map<String, dynamic>? productData;

  /// Firestore document ID for real-time config sync.
  final String? productId;

  /// Product category (for category-wise discount).
  final String? category;

  const ProductDetailsScreen({
    super.key,
    required this.modelNo,
    required this.imageUrl,
    this.productData,
    this.productId,
    this.category,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();

  /// Parses the finish list from a Firestore product document.
  /// Returns null if no valid finishes are present (legacy fallback applies).
  /// Pure function — testable without Firestore or widget state.
  ///
  /// Note: an explicitly empty list is treated the same as a missing
  /// field (returns null → hardcoded default). The Admin Panel validates
  /// "Select At Least One Finish" and cannot save an empty list via UI,
  /// so empty only occurs from legacy data or manual edits. Showing the
  /// default list is safer than showing no finishes (which would break
  /// the finish selector and cart flow).
  static List<String>? parseProductFinishes(
      Map<String, dynamic>? data) {
    final raw = data?['finishes'];
    if (raw is! List || raw.isEmpty) return null;
    final loaded = raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return loaded.isEmpty ? null : loaded;
  }
}

/// Inner view that holds all product detail state.
/// Keyed by configuration so admin updates trigger a clean rebuild.
class _ProductDetailsBody extends StatefulWidget {
  final String modelNo;
  final String imageUrl;
  final Map<String, dynamic>? productData;
  final String? category;

  const _ProductDetailsBody({
    super.key,
    required this.modelNo,
    required this.imageUrl,
    this.productData,
    this.category,
  });

  @override
  State<_ProductDetailsBody> createState() =>
      _ProductDetailsBodyState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  // Real-time sync wrapper state.

  /// Builds a stable key from product config.
  static String _configKey(Map<String, dynamic>? data) {
    if (data == null) return 'nodata';
    final finishes = (data['finishes'] as List?)
            ?.map((e) => e.toString())
            .join(',') ??
        '';
    final sizes = (data['sizes'] as List?)
            ?.map((e) => e.toString())
            .join(',') ??
        '';
    final mrp = data['mrp']?.toString() ?? '';
    return '$finishes|$sizes|$mrp'.hashCode.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pid = widget.productId;
    if (pid != null && pid.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(pid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Text(
                  'Something went wrong',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          final liveData = snapshot.data?.data();
          final effectiveData = liveData ?? widget.productData;
          return _ProductDetailsBody(
            key: ValueKey(_configKey(effectiveData)),
            modelNo: widget.modelNo,
            imageUrl: widget.imageUrl,
            productData: effectiveData,
            category: widget.category,
          );
        },
      );
    }
    return _ProductDetailsBody(
      modelNo: widget.modelNo,
      imageUrl: widget.imageUrl,
      productData: widget.productData,
      category: widget.category,
    );
  }
}

class _ProductDetailsBodyState
    extends State<_ProductDetailsBody> {
  // ---- Warm champagne palette (matches locked theme) ----
  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _goldDeep = Color(0xFF8A6A2F);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  String selectedFinish = "CP";
  CartItem? existingCartItem;

  /// Layer link for positioning the finish dropdown menu below
  /// the selector card.
  final LayerLink _finishMenuLink = LayerLink();

  /// Currently displayed finish menu overlay, if open.
  OverlayEntry? _finishMenuEntry;

  /// Finishes available for this product, loaded from
  /// `productData['finishes']` in initState. Falls back to
  /// the hardcoded list for legacy products without embedded finishes.
  List<String> finishes = [
    "CP",
    "SATIN",
    "ANTIQUE",
    "GOLD",
    "ROSEGOLD",
    "Z.BLACK",
    "B.SATIN",
  ];

  /// Quantity per size (PCS, canonical unit). Keys determine which
  /// size rows are displayed. Initialized from Firestore in initState.
  final Map<String, int> qty = {};

  /// Effective MOQ per size in PCS (after SET→PCS conversion).
  /// Empty = size is misconfigured and cannot be ordered.
  final Map<String, int> moq = {};

  /// Effective Box Qty per size in PCS (after SET→PCS conversion).
  final Map<String, int> boxQty = {};

  /// Display labels per size, e.g. "MOQ : 5 SET" / "BOX QTY : 10 PCS".
  /// Falls back to PCS formatting when no unit metadata exists.
  final Map<String, String> _moqLabel = {};
  final Map<String, String> _boxLabel = {};

  /// Sizes with missing/invalid MOQ or Box Qty. Their + button is
  /// disabled and a warning is shown; they are excluded from cart.
  final Set<String> _misconfiguredSizes = {};

  /// Parses an int from Firestore (int, numeric String, or null).
  static int? _parseQtyInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  /// Builds qty/moq/boxQty maps from productData['sizes'].
  /// Each entry: {"size": "96 MM", "moq": 48, "boxQty": 24,
  ///   "moqUnit": "SET", "boxQtyUnit": "PCS", "pcsPerSet": 2}.
  /// Units default to PCS; SET values are converted via pcsPerSet.
  /// Sizes with invalid config go to _misconfiguredSizes (no silent
  /// defaults — a misconfigured size cannot be ordered).
  void _loadQuantityConfig() {
    final data = widget.productData;
    final sizes = data?['sizes'];
    if (sizes is! List) return;

    for (final s in sizes) {
      if (s is! Map) continue;
      final name = (s['size'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      final moqRaw = _parseQtyInt(s['moq']);
      final boxRaw = _parseQtyInt(s['boxQty']);
      final moqUnit =
          (s['moqUnit']?.toString() ?? 'PCS').toUpperCase();
      final boxUnit =
          (s['boxQtyUnit']?.toString() ?? 'PCS').toUpperCase();
      final pcsPerSet = _parseQtyInt(s['pcsPerSet']) ?? 1;

      // Validate: positive integers required; SET needs valid pcsPerSet.
      final valid = moqRaw != null &&
          moqRaw > 0 &&
          boxRaw != null &&
          boxRaw > 0 &&
          pcsPerSet > 0 &&
          !(moqUnit == 'SET' && s['pcsPerSet'] == null) &&
          !(boxUnit == 'SET' && s['pcsPerSet'] == null);

      if (!valid) {
        _misconfiguredSizes.add(name);
        qty[name] = 0;
        // ignore: avoid_print
        print(
            'MOQ/BoxQty misconfigured for ${widget.modelNo} / $name');
        continue;
      }

      final moqPcs =
          moqRaw! * (moqUnit == 'SET' ? pcsPerSet : 1);
      final boxPcs =
          boxRaw! * (boxUnit == 'SET' ? pcsPerSet : 1);

      qty[name] = 0;
      moq[name] = moqPcs;
      boxQty[name] = boxPcs;
      _moqLabel[name] = 'MOQ : $moqRaw $moqUnit';
      _boxLabel[name] = 'BOX QTY : $boxRaw $boxUnit';
    }
  }

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
  ///
  /// Reads from Firestore `products/{id}.mrp` (finish-wise).
  /// Falls back to legacy size-wise formats for backward compat.
  /// Returns null when MRP is unavailable — caller must show
  /// "Price not available" instead of guessing.
  double? _mrpFor(String finish, String size) {
    // 1. Firestore finish-wise MRP (new schema).
    final finishMrp = _mrpByFinish[finish];
    if (finishMrp != null) {
      final val = finishMrp[size];
      if (val != null) return val;
    }
    // 2. Legacy size-wise MRP (backward compat).
    final fs = _mrpFs[size];
    if (fs != null) return fs;
    // 3. No MRP available — do NOT silently use hardcoded values.
    // The UI must show "Price not available — contact admin".
    return null;
  }

  /// Size-wise MRP from Firestore (null when not available).
  final Map<String, double> _mrpFs = {};

  /// Finish-wise MRP from Firestore: finish -> size -> MRP.
  /// New schema from Admin Panel pricing management.
  final Map<String, Map<String, double>> _mrpByFinish = {};

  /// Dealer discount percentage (0 when missing).
  double _discountPct = 0;
  String _discountSource = 'none';
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
    _loadFinishes();
    _loadQuantityConfig();
    _loadPricing();
  }

  @override
  void dispose() {
    _dismissFinishMenu();
    super.dispose();
  }

  /// Loads the product-specific finish list from Firestore.
  ///
  /// The Admin Panel saves the selected finishes as `finishes`
  /// (List<String>) on each product document. The Dealer APK displays
  /// only those finishes — deselected finishes disappear on the next
  /// sync without requiring an app restart.
  /// Legacy products without embedded finishes keep the default list.
  /// Dismisses the finish dropdown menu if open.
  void _dismissFinishMenu() {
    _finishMenuEntry?.remove();
    _finishMenuEntry = null;
  }

  /// Shows the finish dropdown menu below the selector card.
  /// Uses a custom overlay with true glassmorphism (BackdropFilter
  /// over transparent background) matching the size cards.
  void _showFinishMenu() {
    if (_finishMenuEntry != null) {
      _dismissFinishMenu();
      return;
    }
    final overlay = Overlay.of(context);
    _finishMenuEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Tap outside to dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _dismissFinishMenu,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _finishMenuLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 52),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 2.5, sigmaY: 2.5),
                    child: Container(
                      color: Colors.black
                          .withValues(alpha: 0.55),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: finishes.map((finish) {
                          final isSelected =
                              finish == selectedFinish;
                          return InkWell(
                            onTap: () {
                              _dismissFinishMenu();
                              _selectFinish(finish);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _gold.withValues(
                                        alpha: 0.12),
                                    width: 0.5,
                                  ),
                                ),
                                color: isSelected
                                    ? _gold.withValues(
                                        alpha: 0.18)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                finish,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? _goldBright
                                      : _ivory,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_finishMenuEntry!);
  }

  /// Handles finish selection from the dropdown.
  /// Updates pricing/discount for the newly selected finish.
  Future<void> _selectFinish(String finish) async {
    if (finish == selectedFinish) return;
    setState(() {
      selectedFinish = finish;
      _pricingLoaded = false;
    });
    final discountResult = await PricingService.discountFor(
        widget.category, finish);
    if (mounted) {
      setState(() {
        _discountPct = discountResult.value;
        _discountSource = discountResult.source;
        _pricingLoaded = true;
      });
    }
  }

  void _loadFinishes() {
    final loaded = ProductDetailsScreen.parseProductFinishes(
        widget.productData);
    if (loaded != null) {
      finishes = loaded;
      // Keep the selected finish valid for this product.
      if (!finishes.contains(selectedFinish)) {
        selectedFinish = finishes.first;
      }
    }
  }

  /// Reads MRP from the product document.
  /// New schema: productData['mrp'][finish][size] (finish-wise).
  /// Legacy: productData['sizes'] list or ['mrps'] flat map (size-wise).
  /// Missing data is handled gracefully (null = price unavailable).
  Future<void> _loadPricing() async {
    final data = widget.productData;
    if (data != null) {
      // New schema: finish-wise MRP from Admin Panel.
      final mrpData = data['mrp'];
      if (mrpData is Map) {
        mrpData.forEach((finishKey, sizeMap) {
          if (sizeMap is Map) {
            final finish = finishKey.toString();
            _mrpByFinish[finish] ??= {};
            sizeMap.forEach((sizeKey, mrpVal) {
              if (mrpVal is num) {
                _mrpByFinish[finish]![
                        sizeKey.toString()] =
                    mrpVal.toDouble();
              }
            });
          }
        });
      }
      // Legacy: size-wise from 'sizes' list.
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
      // Legacy: flat map {"96 MM": 100, ...}
      final mrps = data['mrps'];
      if (mrps is Map) {
        mrps.forEach((k, v) {
          if (v is num) _mrpFs[k.toString()] = v.toDouble();
        });
      }
    }

    // Dealer discount: finish > category > dealer fallback.
    // Only ONE discount applied, never combined.
    final discountResult =
        await PricingService.discountFor(
            widget.category, selectedFinish);
    _discountPct = discountResult.value;
    _discountSource = discountResult.source;

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
                        // Compact horizontal finish selector — one
                        // dropdown replacing the multi-chip Wrap.
                        // Options come from Firestore via `finishes`.
                        Row(
                          children: [
                            const Text(
                              "COLOUR",
                              style: TextStyle(
                                color: _ivory,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CompositedTransformTarget(
                                link: _finishMenuLink,
                                child: GestureDetector(
                                  onTap: _showFinishMenu,
                                  child: Container(
                                    // Reduced height vs previous
                                    // implementation.
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  12),
                                      border:
                                          Border.all(
                                        color: _gold
                                            .withValues(
                                                alpha:
                                                    0.28),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  12),
                                      child:
                                          BackdropFilter(
                                        filter: ImageFilter
                                            .blur(
                                                sigmaX:
                                                    2.5,
                                                sigmaY:
                                                    2.5),
                                        child:
                                            Container(
                                          color: Colors
                                              .black
                                              .withValues(
                                                  alpha:
                                                      0.12),
                                          // Stack keeps the
                                          // finish name centered
                                          // while the arrow stays
                                          // right-aligned.
                                          child: Stack(
                                            alignment:
                                                Alignment
                                                    .center,
                                            children: [
                                              Text(
                                                finishes.contains(
                                                        selectedFinish)
                                                    ? selectedFinish
                                                    : "Select",
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      _ivory,
                                                  fontSize:
                                                      13,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  letterSpacing:
                                                      0.5,
                                                ),
                                              ),
                                              const Positioned(
                                                right: 12,
                                                child:
                                                    Icon(
                                                  Icons
                                                      .keyboard_arrow_down,
                                                  color:
                                                      _gold,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                      16, 6, 16, 8),
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
                          // If MRP unavailable, show clear error state.
                          if (mrp == null ||
                              price == null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                      top: 4),
                              child: Text(
                                'Price not available — contact admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle:
                                      FontStyle.italic,
                                  color: _muted,
                                ),
                              ),
                            ),
                          if (mrp != null &&
                              price != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                      top: 2),
                              child: Column(
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
                                      'MRP : ${_inr0.format(mrp)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _finishColor,
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
                                const SizedBox(height: 2),
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
                                          fontSize: 14,
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
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight
                                                  .w500,
                                          color:
                                              _finishColor,
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
                      const SizedBox(height: 6),
                      // ---- MIDDLE: quantity controls ----
                      // Misconfigured sizes: buttons disabled, no silent
                      // defaults — the size cannot be ordered.
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _qtyButton(
                            icon: Icons.remove,
                            iconColor: _finishColor,
                            onPressed: _misconfiguredSizes
                                    .contains(size)
                                ? null
                                : () {
                                    setState(() {
                                      if (qty[size] ==
                                          0) {
                                        return;
                                      }
                                      if (qty[size] ==
                                          moq[size]) {
                                        qty[size] =
                                            0;
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
                            onPressed: _misconfiguredSizes
                                    .contains(size)
                                ? null
                                : () {
                                    setState(() {
                                      if (qty[size] ==
                                          0) {
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
                      const SizedBox(height: 6),
                      // ---- BOTTOM: box qty | MOQ ----
                      Container(
                        padding:
                            const EdgeInsets.only(
                                top: 6, bottom: 6),
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
                                _misconfiguredSizes
                                        .contains(
                                            size)
                                    ? 'QTY NOT CONFIGURED'
                                    : (_boxLabel[
                                            size] ??
                                        'BOX QTY : ${boxQty[size]} PCS'),
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
                                _misconfiguredSizes
                                        .contains(
                                            size)
                                    ? 'CONTACT ADMIN'
                                    : (_moqLabel[
                                            size] ??
                                        'MOQ : ${moq[size]} PCS'),
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
    required VoidCallback? onPressed,
    Color? iconColor,
  }) {
    final ic = iconColor ?? _gold;
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.3 : 1.0,
      child: Pressable(
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

    // Block misconfigured sizes: no silent defaults allowed.
    final misconfigured = selectedSizes
        .where((e) => _misconfiguredSizes.contains(e.key))
        .map((e) => e.key)
        .toList();
    if (misconfigured.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Quantity not configured for ${misconfigured.join(", ")} — contact admin.",
          ),
        ),
      );
      return;
    }

    // Verify all selected sizes have pricing.
    // Do not allow incorrectly priced orders.
    final missingPrice = <String>[];
    qty.forEach((size, q) {
      if (q > 0) {
        final price = _dealerPrice(selectedFinish, size);
        if (price == null) missingPrice.add(size);
      }
    });
    if (missingPrice.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Price not available for ${missingPrice.join(", ")} — contact admin.",
          ),
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
