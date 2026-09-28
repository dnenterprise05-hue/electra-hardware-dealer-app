import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case "pending":
      return Colors.orange;

    case "processing":
      return Colors.blue;

    case "dispatched":
      return Colors.green;

    case "delivered":
      return Colors.green;

    default:
      return Colors.grey;
  }
}
  @override
  Widget build(BuildContext context) {
    final List products = order["products"] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          Card(
  color: Colors.white,
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
            order["orderNo"] ?? "-",
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
            "📅 ${order["date"]}",
            style: const TextStyle(fontSize: 15),
          ),
        ),

        Text(
          "🕒 ${order["time"]}",
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
        color: getStatusColor(order["status"]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        order["status"],
        style: const TextStyle(
          color: Colors.white,
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

          ...products.map((product) {

            final quantities =
                product["quantities"] as Map<String, dynamic>;
                print("QUANTITIES => $quantities");
                debugPrint(quantities.toString());
                const sizeOrder = [
  "96MM",
  "160MM",
  "224MM",
  "288MM",
  "448MM",
  "576MM",
  "896MM",
  "1152MM",
];

            return Card(
              color: Colors.white,
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
      product["imageUrl"],
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
                      product["modelNo"],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Finish : ${product["finish"]}",
                    ),

                    const SizedBox(height: 12),

                    ...sizeOrder
    .where((size) => (quantities[size] ?? 0) > 0)
    .map(
      (size) => Container(
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
  size.replaceAll("MM", " MM"),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
  "${quantities[size]} PCS",
  style: const TextStyle(
    color: Colors.black87,
    fontWeight: FontWeight.w600,
    fontSize: 15,
  ),
),
          ],
        ),
      ),
    )
    .toList(),

                  ],
                ),
              ),
            );

          }),
          const SizedBox(height: 10),

Card(
  color: Colors.white,
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
      ),
    );
  }
}