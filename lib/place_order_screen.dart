import 'dart:ui';
import 'package:flutter/material.dart';
import 'category_products_screen.dart';
import 'cart_screen.dart';
import 'services/cart_service.dart';

/// Place Order main — luxury showroom theme.
///
/// UI-only redesign. Category list, navigation and cart behavior
/// are unchanged from the previous implementation.
class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  // ---- Warm champagne palette (matches locked dashboard theme) ----
  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _goldDeep = Color(0xFF8A6A2F);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  static const _categories = [
    "Zinc Cabinet Handles",
    "Aluminium Cabinet & Door Handles",
    "Zinc Mortise Handles",
    "Kadi, Knobs & Door Stoppers",
    "Commercial Cabinet Handles",
  ];

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
                      const Expanded(
                        child: Text(
                          "PLACE ORDER",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ivory,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      24, 10, 24, 0),
                  child: Container(
                    width: 38,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_goldDeep, _goldBright],
                      ),
                      borderRadius:
                          BorderRadius.circular(1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= DARK-GLASS SEARCH =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  child: TextField(
                    style: const TextStyle(color: _ivory),
                    decoration: InputDecoration(
                      hintText: "Search by Model No.",
                      hintStyle: TextStyle(
                        color: _muted.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _gold,
                        size: 20,
                      ),
                      filled: true,
                      fillColor:
                          Colors.black.withValues(alpha: 0.45),
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _gold.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ================= FLOATING CATEGORY MENU =================
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        28, 4, 28, 24),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return _categoryItem(
                        context,
                        index + 1,
                        _categories[index],
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

  /// Premium category box — subtle rounded champagne-gold outline,
  /// same language as the product list model boxes. No fill, no shadow.
  static Widget _categoryItem(
    BuildContext context,
    int number,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      // ~10% frosted glass: whisper of blur + faint dark tint.
      // Background stays clearly visible through the card.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryProductsScreen(
                      category: title,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _gold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$number",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _ivory,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.chevron_right,
                      color: _gold.withValues(alpha: 0.8),
                      size: 22,
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
