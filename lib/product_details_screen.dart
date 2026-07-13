import 'package:flutter/material.dart';
import 'models/cart_item.dart';
import 'services/cart_service.dart';
import 'cart_screen.dart';
import 'services/favourite_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String modelNo;
  final String imageUrl;

  const ProductDetailsScreen({
    super.key,
    required this.modelNo,
    required this.imageUrl,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {

  String selectedFinish = "CP";
  CartItem? existingCartItem;

  final List<String> finishes = [
  "CP",
  "SATIN",
  "ANTIQUE",
  "GOLD",
  "ROSEGOLD",
  "Z.BLACK",
  "B.SATIN",
];

  final Map<String, int> qty = {
    "96 MM": 0,
    "160 MM": 0,
    "224 MM": 0,
    "288 MM": 0,
  };

  final Map<String, int> moq = {
    "96 MM": 48,
    "160 MM": 32,
    "224 MM": 12,
    "288 MM": 10,
  };

  final Map<String, int> boxQty = {
  "96 MM": 24,
  "160 MM": 16,
  "224 MM": 12,
  "288 MM": 10,
};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
  centerTitle: true,

  title: Text(widget.modelNo),

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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [            Center(
  child: Stack(
    children: [

      Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            widget.imageUrl,
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

      Positioned(
        top: 12,
        right: 12,
        child: AnimatedBuilder(
          animation: FavouriteService.instance,
          builder: (context, child) {

            final fav = FavouriteService.instance.isFavourite(
              widget.modelNo,
            );

            return GestureDetector(
              onTap: () {
                FavouriteService.instance.toggleFavourite(
  modelNo: widget.modelNo,
  imageUrl: widget.imageUrl,
);
              },
              child: Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.95),
    shape: BoxShape.circle,
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Icon(
    fav
        ? Icons.favorite
        : Icons.favorite_border,
    color: Colors.red,
    size: 24,
  ),
),
            );
          },
        ),
      ),

    ],
  ),
),
                   
            const SizedBox(height: 25),

const Text(
  "Select Finish",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: finishes.map((finish) {
                final selected =
                    finish == selectedFinish;

                return ChoiceChip(
                  label: Text(finish),

                  selected: selected,

                  backgroundColor: Colors.white,
selectedColor: Colors.red,

                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.black,
                  ),

                  onSelected: (_) {
  setState(() {
    selectedFinish = finish;
  });
},
                );
              }).toList(),
            ),

            const SizedBox(height: 30),            ...qty.keys.map((size) {
              return Card(
  color: Colors.white,
  elevation: 4,
  shadowColor: Colors.black12,
  margin: const EdgeInsets.only(bottom: 15),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        size,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "MOQ : ${moq[size]} PCS",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                        children: [

                          IconButton(
                          onPressed: () {
  setState(() {
    if (qty[size] == 0) {
      return;
    }

    if (qty[size] == moq[size]) {
      qty[size] = 0;
    } else {
      qty[size] = qty[size]! - boxQty[size]!;
    }
  });
},

                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                              size: 34,
                            ),
                          ),

                          Text(
                            qty[size].toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          IconButton(
                           onPressed: () {
  setState(() {
    if (qty[size] == 0) {
      qty[size] = moq[size]!;
    } else {
      qty[size] = qty[size]! + boxQty[size]!;
    }
  });
},

                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.green,
                              size: 34,
                            ),
                          ),

                        ],
                      ),

                    ],
                  ),
                ),
              );
            }).toList(),
                        const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {

                  final selectedSizes = qty.entries
                      .where((e) => e.value > 0)
                      .toList();

                  if (selectedSizes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please select quantity.",
                        ),
                      ),
                    );
                    return;
                  }
final existing = CartService.findCartItem(
  modelNo: widget.modelNo,
  finish: selectedFinish,
  quantities: qty,
);
if (existing != null) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Already in Cart"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text("Finish : ${existing.finish}"),

          const SizedBox(height: 10),

          ...existing.quantities.entries
              .where((e) => e.value > 0)
              .map(
                (e) => Text(
                  "${e.key} → ${e.value} PCS",
                ),
              ),

          const SizedBox(height: 15),

          const Text(
            "Adding again will increase the quantity.",
          ),

        ],
      ),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("CANCEL"),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);

            CartService.addToCart(
              CartItem(
                modelNo: widget.modelNo,
                imageUrl: widget.imageUrl,
                finish: selectedFinish,
                quantities: Map.from(qty),
              ),
            );

            setState(() {
              qty.updateAll((key, value) => 0);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Product added to cart"),
              ),
            );

            Navigator.pop(this.context);
          },
          child: const Text("ADD ANYWAY"),
        ),

      ],
    ),
  );

  return;
}
                  CartService.addToCart(
  CartItem(
    modelNo: widget.modelNo,
    imageUrl: widget.imageUrl,
    finish: selectedFinish,
    quantities: Map.from(qty),
  ),
);

setState(() {
  qty.updateAll((key, value) => 0);
});

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Product added to cart"),
    duration: Duration(seconds: 2),
  ),
);

Navigator.pop(context);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                icon: const Icon(Icons.shopping_cart),

                label: const Text(
                  "ADD TO CART",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

          ],
        ),
      ),
    );
  }
}