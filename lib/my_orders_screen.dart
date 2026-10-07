import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details_screen.dart';
import 'services/dealer_service.dart';

/// My Orders — luxury showroom theme.
///
/// UI-only redesign. Mobile resolution, newest-first sort, dealer
/// order query and Order Details navigation are unchanged.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _goldDeep = Color(0xFF8A6A2F);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  String? _mobile;
  bool _loading = true;
  bool _mobileError = false;

  @override
  void initState() {
    super.initState();
    _resolveMobile();
  }

  /// Resolves the normalized 10-digit dealer mobile used for the
  /// server-side order query. Never falls back to reading the whole
  /// orders collection.
  Future<void> _resolveMobile() async {
    final user = FirebaseAuth.instance.currentUser;

    String? mobile = DealerService.normalizeMobile10(user?.phoneNumber);

    if (mobile == null) {
      // Fallback: dealer master record via the established identity lookup.
      final dealerDoc = await DealerService.getDealerDoc();
      final dealerData = dealerDoc?.data();
      mobile =
          DealerService.normalizeMobile10(dealerData?["mobile"]?.toString());
    }

    if (!mounted) return;
    setState(() {
      _mobile = mobile;
      _mobileError = mobile == null;
      _loading = false;
    });
  }

  /// Newest-first sort on the already server-filtered docs.
  /// (No composite index needed: the Firestore query has no orderBy.)
  int _compareNewestFirst(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final ca = a.data()["createdAt"];
    final cb = b.data()["createdAt"];
    final ta = ca is Timestamp ? ca : null;
    final tb = cb is Timestamp ? cb : null;
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return tb.compareTo(ta);
  }

  @override
  Widget build(BuildContext context) {
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
                          "MY ORDERS",
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
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _gold),
      );
    }

    if (_mobileError || _mobile == null) {
      // Never query the entire orders collection without a dealer filter.
      return const Center(
        child: Text(
          "Could not verify dealer. Please login again.",
          style: TextStyle(color: _ivory),
        ),
      );
    }

    // Server-side dealer filtering: only this dealer's orders are
    // downloaded. Single-field where: no composite index required.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("orders")
          .where(
            "dealerMobile",
            isEqualTo: _mobile,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: _ivory),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _gold),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No Orders Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _ivory,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        final orders = docs.toList()..sort(_compareNewestFirst);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data();

            final rawProducts = data["products"];
            final List products =
                rawProducts is List ? rawProducts : [];

            final status = data["status"]?.toString();
            final statusLabel = status ?? "Unknown";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.35),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 2.5, sigmaY: 2.5),
                  child: Container(
                    color:
                        Colors.black.withValues(alpha: 0.10),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OrderDetailsScreen(
                              order: data,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.all(15),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    data["orderNo"]
                                            ?.toString() ??
                                        "Order",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: _ivory,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    "${data["date"] ?? "-"}",
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: _ivorySoft,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      20),
                                          border:
                                              Border.all(
                                            color: _gold
                                                .withValues(
                                                    alpha:
                                                        0.6),
                                          ),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style:
                                              const TextStyle(
                                            color: _goldBright,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            fontSize: 12.5,
                                            letterSpacing:
                                                0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: 10),
                                      Text(
                                        "${products.length} Model",
                                        style:
                                            const TextStyle(
                                          color: _muted,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: _gold.withValues(
                                  alpha: 0.7),
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
