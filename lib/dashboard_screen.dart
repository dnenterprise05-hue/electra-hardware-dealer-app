import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'place_order_screen.dart';
import 'services/dealer_service.dart';
import 'my_orders_screen.dart';
import 'contact_us_screen.dart';
import 'profile_screen.dart';
import 'favourite_screen.dart';

/// Dashboard on the locked Dealer Login background.
///
/// "Dealer Login background + premium gold dashboard cards".
/// UI-only change. All navigation routes and dealer-data logic are
/// unchanged from the previous implementation.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ---- Electra gold accents (matches locked login theme) ----
  static const _gold = Color(0xFFC9A45C);
  static const _goldLight = Color(0xFFE9CB8B);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFCFC6B8);
  static const _textMuted = Color(0xFF9A9184);

  @override
  Widget build(BuildContext context) {
    // Dealer identity comes from the mobile-based lookup done at OTP login.
    // Admin dealer documents use auto-generated IDs, so the document ID
    // can NOT be assumed to equal the Firebase Auth UID.
    final dealerDocId = DealerService.dealerDocId;

    if (dealerDocId == null || dealerDocId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            "Dealer Not Found",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("dealers")
            .doc(dealerDocId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Dealer Not Found",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            );
          }

          final dealer = snapshot.data!.data() as Map<String, dynamic>;

          // Tolerate the Admin dealer schema: `gstNumber` instead of `gst`,
          // and possibly missing city/state.
          final location = DealerService.locationOf(dealer);
          final gst = DealerService.gstOf(dealer);

          return Stack(
            fit: StackFit.expand,
            children: [
              // EXACT same background asset as the locked Dealer Login.
              Image.asset(
                'assets/login_background.png',
                fit: BoxFit.cover,
              ),
              // Deep dark overlay: the login background becomes a
              // subtle premium texture instead of a visible photo.
              Container(
                color: Colors.black.withValues(alpha: 0.78),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // ================= COMPACT HEADER =================
                    // Dealer identity only — the brand logo lives in the
                    // background itself, so no logo/title is added here.
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 14, 24, 0),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            dealer["firmName"] ?? "",
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: _gold,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location.isEmpty ? "—" : location,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_outlined,
                                size: 14,
                                color: _gold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "GSTIN : $gst",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color:
                                  _gold.withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ================= ACTION GRID =================
                    // Taller cards, rows distributed across the screen.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            20, 0, 20, 16),
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.92,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          children: [
                            _dashboardCard(
                              context,
                              Icons.shopping_cart_outlined,
                              "Place Order",
                              isPrimary: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PlaceOrderScreen(),
                                  ),
                                );
                              },
                            ),
                            _dashboardCard(
                              context,
                              Icons.inventory_2_outlined,
                              "My Orders",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MyOrdersScreen(),
                                  ),
                                );
                              },
                            ),
                            _dashboardCard(
                              context,
                              Icons
                                  .account_balance_wallet_outlined,
                              "Ledger",
                              onTap: () {},
                            ),
                            _dashboardCard(
                              context,
                              Icons.favorite_border,
                              "Favourite",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FavouriteScreen(),
                                  ),
                                );
                              },
                            ),
                            _dashboardCard(
                              context,
                              Icons.person_outline,
                              "Profile",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfileScreen(),
                                  ),
                                );
                              },
                            ),
                            _dashboardCard(
                              context,
                              Icons.support_agent,
                              "Contact Us",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ContactUsScreen(),
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
            ],
          );
        },
      ),
    );
  }

  static Widget _dashboardCard(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        // Dark translucent charcoal — lets the login background
        // breathe through while keeping cards readable.
        color: const Color(0xFF17140F).withValues(alpha: 0.87),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(
            alpha: isPrimary ? 0.55 : 0.22,
          ),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          if (isPrimary)
            BoxShadow(
              color: _gold.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(
                    alpha: isPrimary ? 0.15 : 0.09,
                  ),
                  border: Border.all(
                    color: _gold.withValues(
                      alpha: isPrimary ? 0.5 : 0.28,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 25,
                  color: isPrimary ? _goldLight : _gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isPrimary
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: _textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
