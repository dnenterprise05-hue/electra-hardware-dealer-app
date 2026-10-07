import 'dart:ui';
import 'package:flutter/material.dart';
import 'widgets/pressable.dart';
import 'models/cart_item.dart';
import 'services/cart_service.dart';
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

  const ProductDetailsScreen({
    super.key,
    required this.modelNo,
    required this.imageUrl,
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
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              border: Border.all(
                                color: _gold.withValues(
                                    alpha: 0.3),
                              ),
                            ),
                            // ~10% frosted glass, same as the
                            // rest of the Place Order flow.
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 2.5,
                                    sigmaY: 2.5),
                                child: Container(
                                  color: Colors.black
                                      .withValues(
                                          alpha: 0.10),
                                  padding:
                                      const EdgeInsets
                                          .all(16),
                                  child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Text(
                                      size,
                                      style:
                                          const TextStyle(
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: _ivory,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    Text(
                                      "MOQ : ${moq[size]} PCS",
                                      style:
                                          const TextStyle(
                                        fontSize: 13,
                                        color: _gold,
                                        fontWeight:
                                            FontWeight.w600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    _qtyButton(
                                      icon: Icons.remove,
                                      onPressed: () {
                                        setState(() {
                                          if (qty[size] ==
                                              0) {
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
                                      style:
                                          const TextStyle(
                                        fontSize: 22,
                                        fontWeight:
                                            FontWeight.w700,
                                        color: _ivory,
                                      ),
                                    ),
                                    _qtyButton(
                                      icon: Icons.add,
                                      onPressed: () {
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
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
  static Widget _qtyButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Pressable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _gold.withValues(alpha: 0.55),
          ),
        ),
        child: Icon(icon, color: _gold, size: 20),
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
                CartService.addToCart(
                  CartItem(
                    modelNo: widget.modelNo,
                    imageUrl: widget.imageUrl,
                    finish: selectedFinish,
                    quantities: Map.from(qty),
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

    CartService.addToCart(
      CartItem(
        modelNo: widget.modelNo,
        imageUrl: widget.imageUrl,
        finish: selectedFinish,
        quantities: Map.from(qty),
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
