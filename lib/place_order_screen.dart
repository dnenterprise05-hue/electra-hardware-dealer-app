import 'package:flutter/material.dart';
import 'category_products_screen.dart';
import 'cart_screen.dart';
import 'services/cart_service.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() =>
      _PlaceOrderScreenState();
}

class _PlaceOrderScreenState
    extends State<PlaceOrderScreen> {

  @override
  Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.grey.shade100,

appBar: AppBar(
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
  centerTitle: true,

  title: const Text(
    "Place Order",
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),

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

    const SizedBox(width: 10),

  ],
),

body: Padding(
padding: const EdgeInsets.all(16),

child: Column(
children: [

TextField(
decoration: InputDecoration(
hintText: "Search by Model No.",
prefixIcon: const Icon(Icons.search),

filled: true,
fillColor: Colors.white,

border: OutlineInputBorder(
borderRadius: BorderRadius.circular(15),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 20),

const Align(
alignment: Alignment.centerLeft,
child: Text(
"Categories",
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
),

const SizedBox(height: 15),

Expanded(
child: ListView(
children: [

  categoryTile(
    context,
    "Zinc Cabinet Handles",
  ),

  categoryTile(
    context,
    "Aluminium Cabinet & Door Handles",
  ),

  categoryTile(
    context,
    "Zinc Mortise Handles",
  ),

  categoryTile(
    context,
    "Kadi, Knobs & Door Stoppers",
  ),

  categoryTile(
    context,
    "Commercial Cabinet Handles",
  ),
],
),
),
],
),
),
);
}

static Widget categoryTile(
    BuildContext context,
    String title,
    ) {
return Card(
elevation: 3,
color: Colors.white,
margin: const EdgeInsets.only(bottom: 12),

shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),

child: ListTile(
contentPadding: const EdgeInsets.symmetric(
horizontal: 18,
vertical: 4,
),

title: Text(
title,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.w600,
color: Colors.black,
),
),

trailing: const Icon(
Icons.chevron_right,
color: Colors.red,
size: 28,
),

  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsScreen(
          category: title,
        ),
      ),
    );
  },
),
);
}
}