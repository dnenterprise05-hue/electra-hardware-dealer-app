import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'services/dealer_service.dart';
import 'services/pin_service.dart';

/// Profile — luxury showroom theme.
///
/// UI-only redesign. Dealer data stream, field mapping and the
/// logout flow (sign out + clear session + clear PIN + stack reset)
/// are unchanged.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  @override
  Widget build(BuildContext context) {
    // Dealer identity comes from the mobile-based lookup done at OTP login
    // (Admin dealer documents use auto-generated IDs, not the Auth UID).
    final dealerDocId = DealerService.dealerDocId;

    if (dealerDocId == null || dealerDocId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/login_background.png',
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
            const SafeArea(
              child: Center(
                child: Text(
                  "Dealer Not Found",
                  style: TextStyle(color: _ivory),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                          "PROFILE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ivory,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("dealers")
                        .doc(dealerDocId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: _gold),
                        );
                      }

                      if (!snapshot.hasData ||
                          !snapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            "Dealer Not Found",
                            style:
                                TextStyle(color: _ivory),
                          ),
                        );
                      }

                      final dealer = snapshot.data!
                          .data() as Map<String, dynamic>;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                            20, 8, 20, 24),
                        child: Column(
                          children: [
                            _glassPanel(
                              child: Column(
                                children: [
                                  _profileTile(
                                    Icons.business_outlined,
                                    "Firm Name",
                                    dealer["firmName"] ??
                                        "",
                                  ),
                                  _divider(),
                                  _profileTile(
                                    Icons.badge_outlined,
                                    "Dealer Code",
                                    dealer["dealerCode"] ??
                                        "",
                                  ),
                                  _divider(),
                                  _profileTile(
                                    Icons.call_outlined,
                                    "Mobile",
                                    dealer["mobile"] ?? "",
                                  ),
                                  _divider(),
                                  _profileTile(
                                    Icons.email_outlined,
                                    "Email",
                                    dealer["email"] ?? "",
                                  ),
                                  _divider(),
                                  _profileTile(
                                    Icons.receipt_long_outlined,
                                    "GST Number",
                                    DealerService.gstOf(
                                        dealer),
                                  ),
                                  _divider(),
                                  _profileTile(
                                    Icons.location_on_outlined,
                                    "Address",
                                    DealerService.addressOf(
                                        dealer),
                                  ),
                                  _divider(),
                                  Padding(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        vertical: 6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .verified_outlined,
                                          color: _gold,
                                          size: 22,
                                        ),
                                        const SizedBox(
                                            width: 14),
                                        const Text(
                                          "Status",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _ivory,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          dealer["isActive"] ==
                                                  true
                                              ? "Active"
                                              : "Inactive",
                                          style:
                                              TextStyle(
                                            color: dealer[
                                                        "isActive"] ==
                                                    true
                                                ? _ivory
                                                : const Color(
                                                    0xFFE08A8A),
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Logout clears everything: the Firebase session,
                                  // the in-memory dealer session, AND the device PIN.
                                  // The whole route stack is removed and the user lands
                                  // directly on LoginScreen: no authenticated route
                                  // (Dashboard, PinScreen, ...) remains underneath, so
                                  // the system Back button can never return to one.
                                  await FirebaseAuth.instance
                                      .signOut();
                                  DealerService.clearSession();
                                  await PinService.clearPin();

                                  if (!context.mounted)
                                    return;
                                  Navigator.of(context)
                                      .pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(
                                    Icons.logout,
                                    size: 20),
                                label: const Text(
                                  "Logout",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor: _gold,
                                  foregroundColor:
                                      Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  /// Frosted glass panel shared by the profile card.
  static Widget _glassPanel({required Widget child}) {
    return Container(
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
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget _divider() {
    return Divider(
      color: _gold.withValues(alpha: 0.15),
      height: 12,
    );
  }

  static Widget _profileTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _gold,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _ivory,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _ivory,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
