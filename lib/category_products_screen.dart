import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'services/cart_service.dart';
import 'services/favourite_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String category;

  const CategoryProductsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends State<CategoryProductsScreen> {

  final TextEditingController searchController =
      TextEditingController();

  String searchText = "";
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
  centerTitle: true,

  title: Text(widget.category),

  actions: [

    InkWell(
      onTap: () async {

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CartScreen(),
          ),
        );

        setState(() {});

      },

      child: Padding(
        padding: const EdgeInsets.only(right: 18),

        child: Row(
          children: [

            const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
            ),

            const SizedBox(width: 5),

            AnimatedBuilder(
  animation: CartService.instance,
  builder: (context, child) {
    return Text(
      "${CartService.totalItems}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
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

      body: Column(
        children: [

          const SizedBox(height: 15),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),

            child: TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },

              decoration: InputDecoration(
                hintText: "Search Model No.",
                prefixIcon:
                    const Icon(Icons.search),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("products")
                  .where(
                    "category",
                    isEqualTo: widget.category
                        .toLowerCase()
                        .replaceAll(" ", "_"),
                  )
                  // Dealer app shows only Admin-activated products.
                  .where(
                    "isActive",
                    isEqualTo: true,
                  )
                  .snapshots(),

              builder: (context, snapshot) {                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Something went wrong"),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                final products = docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final model =
                      (data["modelNo"] ?? "")
                          .toString()
                          .toLowerCase();

                  return model.contains(searchText);
                }).toList();

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Products Found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final data = products[index].data()
                        as Map<String, dynamic>;
                                            return Card(
                      elevation: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        modelNo: data["modelNo"],
        imageUrl: data["imageUrl"],
      ),
    ),
  );
},
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [

                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(15),
                                child: Image.network(
                                  data["imageUrl"],
                                  width: 160,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      width: 160,
                                      height: 120,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.image,
                                        size: 45,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(width: 25),

                              Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [

      Row(
        children: [

          Expanded(
            child: Text(
              data["modelNo"],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          

   
        ],
      ),

      const SizedBox(height: 10),

      const Text(
        "Tap to View",
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),

    ],
  ),
),

                              Padding(
  padding: const EdgeInsets.only(right: 4),
  child: const Icon(
    Icons.chevron_right,
    color: Colors.red,
    size: 38,
  ),
),

                            ],
                          ),
                        ),
                      ),
                    );
                                      },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}