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
        title: Text(order["orderNo"] ?? "Order Details"),
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

                  Text(
                    "Order No : ${order["orderNo"] ?? "-"}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
  children: [

    const Text(
      "Status : ",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),

    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: getStatusColor(
          order["status"],
        ),
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

                  const SizedBox(height: 6),

                  Text(
                    "Date : ${order["date"]}",
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Time : ${order["time"]}",
                    style: const TextStyle(fontSize: 16),
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
      height: 120,
      fit: BoxFit.contain,
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
      (size) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          "$size  →  ${quantities[size]} PCS",
          style: const TextStyle(
            fontSize: 15,
          ),
        ),
      ),
    ),

                  ],
                ),
              ),
            );

          }),

        ],
      ),
    );
  }
}