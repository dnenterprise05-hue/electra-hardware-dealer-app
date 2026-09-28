import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details_screen.dart';
import 'services/dealer_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
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

  /// Badge background: same semantic mapping as Order Details.
  Color _badgeBackground(String? status) {
    switch (status?.toLowerCase()) {
      case "pending":
        return Colors.orange.shade100;
      case "confirmed":
        return Colors.blue.shade100;
      case "processing":
        return Colors.purple.shade100;
      case "dispatched":
        return Colors.indigo.shade100;
      case "delivered":
        return Colors.green.shade100;
      case "cancelled":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  /// Badge text color: same semantic mapping as Order Details.
  Color _badgeForeground(String? status) {
    switch (status?.toLowerCase()) {
      case "pending":
        return Colors.orange.shade900;
      case "confirmed":
        return Colors.blue.shade900;
      case "processing":
        return Colors.purple.shade900;
      case "dispatched":
        return Colors.indigo.shade900;
      case "delivered":
        return Colors.green.shade900;
      case "cancelled":
        return Colors.red.shade900;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_mobileError || _mobile == null) {
      // Never query the entire orders collection without a dealer filter.
      return const Center(
        child: Text("Could not verify dealer. Please login again."),
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
            child: Text(snapshot.error.toString()),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No Orders Found",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final orders = docs.toList()..sort(_compareNewestFirst);

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data();

            final rawProducts = data["products"];
            final List products =
                rawProducts is List ? rawProducts : [];

            final status = data["status"]?.toString();
            final statusLabel = status ?? "Unknown";

            return Card(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black12,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(
                        order: data,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data["orderNo"]?.toString() ?? "Order",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${data["date"] ?? "-"}",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _badgeBackground(status),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: _badgeForeground(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${products.length} Model",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ],
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
