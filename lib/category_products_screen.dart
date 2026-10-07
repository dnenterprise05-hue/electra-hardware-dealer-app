import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'services/cart_service.dart';

/// Category product list — luxury showroom theme.
///
/// UI-only redesign. Firestore query, search filtering, product
/// navigation and cart behavior are unchanged from the previous
/// implementation. Product images are displayed exactly as provided.
class CategoryProductsScreen extends StatefulWidget {
  final String category;

  const CategoryProductsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends State<CategoryProductsScreen> {
  // ---- Warm champagne palette (matches locked dashboard theme) ----
  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _goldDeep = Color(0xFF8A6A2F);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  final TextEditingController searchController =
      TextEditingController();

  String searchText = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // SAME luxury showroom background as the final Dashboard.
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
                      Expanded(
                        child: Text(
                          widget.category.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ivory,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                      InkWell(
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

                const SizedBox(height: 14),

                // ================= DARK-GLASS SEARCH =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  // ~10% frosted glass on the search bar.
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: 2.5, sigmaY: 2.5),
                      child: TextField(
                        controller: searchController,
                        style:
                            const TextStyle(color: _ivory),
                        onChanged: (value) {
                          setState(() {
                            searchText =
                                value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search Model No.",
                          hintStyle: TextStyle(
                            color: _muted.withValues(
                                alpha: 0.8),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: _gold,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.black
                              .withValues(alpha: 0.10),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _gold.withValues(alpha: 0.35),
                        ),
                      ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                            borderSide: BorderSide(
                              color: _gold.withValues(
                                  alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ================= PRODUCT LIST =================
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("products")
                        .where(
                          "category",
                          // Firestore stores the display category name
                          // (e.g. 'Zinc Cabinet Handles'), so query it
                          // directly without snake_case transformation.
                          isEqualTo: widget.category,
                        )
                        // Dealer app shows only Admin-activated products.
                        .where(
                          "isActive",
                          isEqualTo: true,
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            "Something went wrong",
                            style: TextStyle(color: _ivory),
                          ),
                        );
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: _gold,
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      final products = docs.where((doc) {
                        final data = doc.data()
                            as Map<String, dynamic>;

                        final model = (data["modelNo"] ?? "")
                            .toString()
                            .toLowerCase();

                        return model.contains(searchText);
                      }).toList();

                      if (products.isEmpty) {
                        return const Center(
                          child: Text(
                            "No Products Found",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _ivory,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            20, 4, 20, 24),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final data =
                              products[index].data()
                                  as Map<String, dynamic>;
                          return _productRow(
                              context, data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Premium product row — real product photo unchanged, minimal
  /// dark presentation with a thin champagne separator.
  static Widget _productRow(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Subtle rounded outline matching the search field border.
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      // ~10% frosted glass, same as Place Order category boxes.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.10),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailsScreen(
                      modelNo: data["modelNo"],
                      imageUrl: data["imageUrl"],
                    ),
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.all(12),
          child: Row(
          children: [
            // Product photo — displayed exactly as provided.
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                data["imageUrl"],
                width: 110,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    width: 110,
                    height: 84,
                    color: Colors.black
                        .withValues(alpha: 0.5),
                    child: const Icon(
                      Icons.image,
                      size: 34,
                      color: _muted,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    "${data["modelNo"]}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _ivory,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap to View",
                    style: TextStyle(
                      fontSize: 13,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
                  Icon(
                    Icons.chevron_right,
                    color:
                        _gold.withValues(alpha: 0.85),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
