import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'place_order_screen.dart';
import 'services/dealer_service.dart';
import 'my_orders_screen.dart';
import 'contact_us_screen.dart';
import 'profile_screen.dart';
import 'favourite_screen.dart';

/// Premium floating-menu Dashboard on the locked Dealer Login background.
///
/// No cards — six floating menu items over the visible luxury showroom.
/// UI-only change. All navigation routes and dealer-data logic are
/// unchanged from the previous implementation.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ---- Warm champagne palette (matches locked login theme) ----
  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _goldDeep = Color(0xFF8A6A2F);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

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
              color: _ivory,
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
                  color: _ivory,
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
              // The Electra logo inside it stays visible — no logo added.
              Image.asset(
                'assets/login_background.png',
                fit: BoxFit.cover,
              ),
              // Gentle readability gradient: darker at top/bottom,
              // lighter in the middle so the showroom logo breathes.
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.62),
                      Colors.black.withValues(alpha: 0.32),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ================= COMPACT HEADER =================
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(26, 12, 26, 0),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            dealer["firmName"] ?? "",
                            style: const TextStyle(
                              color: _ivory,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: _gold,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location.isEmpty ? "—" : location,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _ivorySoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_outlined,
                                size: 13,
                                color: _gold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "GSTIN : $gst",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _ivorySoft,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 38,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient:
                                  const LinearGradient(
                                colors: [_goldDeep, _goldBright],
                              ),
                              borderRadius:
                                  BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Breathing space: exposes the Electra logo that
                    // lives naturally inside the background image.
                    // The whole menu group sits ~18px lower as one unit.
                    const SizedBox(height: 18),
                    const Spacer(flex: 3),

                    // ================= FLOATING MENU =================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _menuItem(
                                context,
                                Icons.shopping_cart_outlined,
                                "PLACE ORDER",
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
                              _menuItem(
                                context,
                                Icons.inventory_2_outlined,
                                "MY ORDERS",
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
                            ],
                          ),
                          const SizedBox(height: 34),
                          Row(
                            children: [
                              _menuItem(
                                context,
                                Icons
                                    .account_balance_wallet_outlined,
                                "LEDGER",
                                onTap: () {},
                              ),
                              _menuItem(
                                context,
                                Icons.favorite_border,
                                "FAVOURITE",
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
                            ],
                          ),
                          const SizedBox(height: 34),
                          Row(
                            children: [
                              _menuItem(
                                context,
                                Icons.person_outline,
                                "PROFILE",
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
                              _menuItem(
                                context,
                                Icons.support_agent,
                                "CONTACT US",
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
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// One floating premium menu item — no card, no tile, no shadow.
  static Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final iconColor = isPrimary ? _goldBright : _gold;

    return Expanded(
      // Subtle ~10% frosted glass panel around each menu item.
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _gold.withValues(alpha: 0.35),
          ),
        ),
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
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Whisper-thin elegant gold ring only.
                  border: Border.all(
                    color: _gold.withValues(
                      alpha: isPrimary ? 0.55 : 0.32,
                    ),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _ivory,
                  letterSpacing: 1.6,
                  shadows: isPrimary
                      ? [
                          Shadow(
                            color: _gold.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),
                      const SizedBox(height: 7),
                      Container(
                        width: 30,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: _gold.withValues(
                            alpha:
                                isPrimary ? 0.85 : 0.5,
                          ),
                          borderRadius:
                              BorderRadius.circular(1.5),
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
    );
  }
}
