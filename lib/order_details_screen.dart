import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Order Details — luxury showroom theme matching My Orders.
///
/// UI-only redesign. The order document query (single-doc live stream
/// via orderDocId), status values, product/size/quantity/price data
/// and all pricing calculations are unchanged.
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
  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  /// Indian currency formatter (₹9,995). Display only; values unchanged.
  static final _inr0 = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

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

  /// Safely converts a stored quantity value to int (0 when invalid).
  int _quantityValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  /// Safely converts a stored price value to double (null when invalid).
  double? _priceValue(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
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
                          "ORDER DETAILS",
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
                  child: _orderStream == null
                      // Legacy fallback: no orderDocId, render the
                      // passed order statically.
                      ? _buildBody(widget.order)
                      : StreamBuilder<
                          DocumentSnapshot<
                              Map<String, dynamic>>>(
                          stream: _orderStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child:
                                    CircularProgressIndicator(
                                        color: _gold),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Center(
                                child: Text(
                                  "Could not load order details.",
                                  style: TextStyle(
                                      color: _ivory),
                                ),
                              );
                            }
                            final doc = snapshot.data;
                            if (doc == null || !doc.exists) {
                              return const Center(
                                child: Text(
                                  "Order not found.",
                                  style: TextStyle(
                                      color: _ivory),
                                ),
                              );
                            }
                            final data =
                                doc.data() ?? widget.order;
                            return _buildBody(data);
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

  /// Frosted gold-border card used for every section.
  Widget _card(Widget child) {
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
          filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.10),
            padding: const EdgeInsets.all(15),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> order) {
    final rawProducts = order["products"];
    final List products =
        rawProducts is List ? rawProducts : [];
    final statusLabel =
        order["status"]?.toString() ?? "Unknown";

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // Order header card.
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order["orderNo"]?.toString() ?? "Order",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ivory,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                "${order["date"] ?? "-"}"
                "${order["time"] != null ? "  •  ${order["time"]}" : ""}",
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _ivory,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: _ivory,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Products.
        ...products.map((rawProduct) {
          final Map<String, dynamic> product =
              rawProduct is Map
                  ? Map<String, dynamic>.from(rawProduct)
                  : <String, dynamic>{};

          final rawQuantities = product["quantities"];
          final Map<String, dynamic> quantities =
              rawQuantities is Map
                  ? Map<String, dynamic>.from(rawQuantities)
                  : <String, dynamic>{};

          final rawPrices = product["prices"];
          final Map<String, dynamic> prices = rawPrices is Map
              ? Map<String, dynamic>.from(rawPrices)
              : <String, dynamic>{};

          // Use the EXACT keys stored in Firestore (e.g. "96 MM").
          // No hardcoded size list: every stored size key is honored.
          final sizeEntries = quantities.entries
              .where((e) => _quantityValue(e.value) > 0)
              .toList()
            ..sort(
              (a, b) =>
                  _sizeSortKey(a.key).compareTo(_sizeSortKey(b.key)),
            );

          final imageUrl =
              product["imageUrl"]?.toString() ?? "";

          return _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: _gold.withValues(
                                    alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 32,
                              color: _muted,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            product["modelNo"]?.toString() ??
                                "-",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _ivory,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Colour : ${product["finish"] ?? "-"}",
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: _ivory,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Size-wise rows: SIZE → QTY → × → RATE → = → AMOUNT.
                // Same agreed format as the cart screen.
                ...sizeEntries.map((entry) {
                  final price =
                      _priceValue(prices[entry.key]);
                  final qty = _quantityValue(entry.value);
                  final lineTotal = price != null
                      ? (price * qty).roundToDouble()
                      : null;
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            entry.key,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _ivory,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                          child: Icon(
                            Icons.arrow_forward,
                            size: 11,
                            color: _ivory,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            "$qty PCS",
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ivory,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                          child: Text(
                            "\u00d7",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _ivory,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            price != null
                                ? _inr0.format(price)
                                : "",
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ivory,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                          child: Text(
                            "=",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _ivory,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            lineTotal != null
                                ? _inr0.format(lineTotal)
                                : "",
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ivory,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),

        // Order totals (stored values, display only).
        _card(
          Column(
            children: [
              _summaryRow(
                "Taxable Amount",
                order["taxableAmount"],
              ),
              _summaryRow(
                "GST Amount",
                order["gstAmount"],
              ),
              const Divider(
                color: _gold,
                height: 16,
                thickness: 0.5,
              ),
              _summaryRow(
                "GRAND TOTAL",
                order["totalEstimate"],
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Summary row with Indian currency formatting.
  /// Null amounts render as "—"; values are never recalculated here.
  Widget _summaryRow(String label, dynamic amount,
      {bool bold = false}) {
    final text = amount is num
        ? _inr0.format(amount)
        : "—";
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 14,
              color: _ivory,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: bold ? 0.6 : 0,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: bold ? 18 : 15,
              fontWeight: FontWeight.w700,
              color: _ivory,
            ),
          ),
        ],
      ),
    );
  }
}
