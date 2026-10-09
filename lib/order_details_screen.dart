import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _orderStream;

  @override
  void initState() {
    super.initState();
    // Listen to the single order document for live status updates.
    final docId = widget.order["orderDocId"]?.toString();
    if (docId != null && docId.isNotEmpty) {
      _orderStream = FirebaseFirestore.instance
          .collection("orders")
          .doc(docId)
          .snapshots();
    }
  }

  /// Status badge color. UI-only; does not change business logic.
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "confirmed":
        return Colors.blue;
      case "processing":
        return Colors.purple;
      case "dispatched":
        return Colors.indigo;
      case "delivered":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Safely converts a stored quantity value to int (0 when invalid).
  int _quantityValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  /// Sort key for a size label: leading number ("96 MM" -> 96).
  int _sizeSortKey(String key) {
    final match = RegExp(r'\d+').firstMatch(key);
    if (match == null) return 0;
    return int.tryParse(match.group(0)!) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: const Color(0xFFFFF8EE),
      ),
      backgroundColor: Colors.grey.shade100,
      body: _orderStream == null
          // Legacy fallback: no orderDocId, render the passed order statically.
          ? _buildBody(context, widget.order)
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _orderStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Could not load order details."),
                  );
                }
                final doc = snapshot.data;
                if (doc == null || !doc.exists) {
                  return const Center(
                    child: Text("Order not found."),
                  );
                }
                final data = doc.data() ?? widget.order;
                return _buildBody(context, data);
              },
            ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> order) {
    final rawProducts = order["products"];
    final List products = rawProducts is List ? rawProducts : [];
    final String? status = order["status"]?.toString();
    final statusLabel = status ?? "Unknown";

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFFFFF8EE),
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ORDER DETAILS",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order["orderNo"]?.toString() ?? "-",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "\u{1F4C5} ${order["date"] ?? "-"}",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Text(
                          "\u{1F552} ${order["time"] ?? "-"}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: const Color(0xFFFFF8EE),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Products",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...products.map((rawProduct) {
          final Map<String, dynamic> product = rawProduct is Map
              ? Map<String, dynamic>.from(rawProduct)
              : <String, dynamic>{};

          final rawQuantities = product["quantities"];
          final Map<String, dynamic> quantities = rawQuantities is Map
              ? Map<String, dynamic>.from(rawQuantities)
              : <String, dynamic>{};

          // Use the EXACT keys stored in Firestore (e.g. "96 MM").
          // No hardcoded size list: every stored size key is honored.
          final sizeEntries = quantities.entries
              .where((e) => _quantityValue(e.value) > 0)
              .toList()
            ..sort(
              (a, b) => _sizeSortKey(a.key).compareTo(_sizeSortKey(b.key)),
            );

          final imageUrl = product["imageUrl"]?.toString() ?? "";

          return Card(
            color: const Color(0xFFFFF8EE),
            elevation: 4,
            shadowColor: Colors.black12,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    product["modelNo"]?.toString() ?? "-",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Finish : ${product["finish"] ?? "-"}",
                  ),
                  const SizedBox(height: 12),
                  ...sizeEntries.map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.straighten,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            "${_quantityValue(entry.value)} PCS",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFFFFF8EE),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Models",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${products.length}",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
