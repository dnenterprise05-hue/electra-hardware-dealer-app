import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'place_order_screen.dart';
import 'services/dealer_service.dart';
import 'my_orders_screen.dart';
import 'contact_us_screen.dart';
import 'profile_screen.dart';
import 'favourite_screen.dart';

/// Premium dark + gold Electra Hardware dashboard.
///
/// UI-only redesign. All navigation routes and dealer-data logic are
/// unchanged from the previous implementation.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ---- Electra dark-luxury palette (matches locked login theme) ----
  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF161616);
  static const _cardElevated = Color(0xFF1C1A17);
  static const _gold = Color(0xFFC9A45C);
  static const _goldLight = Color(0xFFE9CB8B);
  static const _goldDeep = Color(0xFF8A6A2F);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFB8AEA2);
  static const _textMuted = Color(0xFF7A7268);

  @override
  Widget build(BuildContext context) {
    // Dealer identity comes from the mobile-based lookup done at OTP login.
    // Admin dealer documents use auto-generated IDs, so the document ID
    // can NOT be assumed to equal the Firebase Auth UID.
    final dealerDocId = DealerService.dealerDocId;

    if (dealerDocId == null || dealerDocId.isEmpty) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
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
      backgroundColor: _bg,
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

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF14100C),
                  _bg,
                  _bg,
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ================= BRAND HEADER =================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ELECTRA HARDWARE",
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_goldDeep, _goldLight],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          dealer["firmName"] ?? "",
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: _gold,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location.isEmpty ? "—" : location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_outlined,
                              size: 15,
                              color: _gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "GSTIN : $gst",
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textMuted,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ================= ACTION GRID =================
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.08,
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
                            Icons.account_balance_wallet_outlined,
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
                                  builder: (_) => FavouriteScreen(),
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
                                  builder: (_) => ContactUsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
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
    final borderColor = isPrimary
        ? _gold.withValues(alpha: 0.55)
        : _gold.withValues(alpha: 0.18);

    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? _cardElevated : _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          if (isPrimary)
            BoxShadow(
              color: _gold.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(
                    alpha: isPrimary ? 0.16 : 0.10,
                  ),
                  border: Border.all(
                    color: _gold.withValues(
                      alpha: isPrimary ? 0.45 : 0.25,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: isPrimary ? _goldLight : _gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isPrimary ? FontWeight.w700 : FontWeight.w600,
                  color: _textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              if (isPrimary) ...[
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
