import 'package:flutter/material.dart';
import 'services/favourite_service.dart';
import 'product_details_screen.dart';

class FavouriteScreen extends StatelessWidget {
  FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Favourite"),
      ),

      body: AnimatedBuilder(
        animation: FavouriteService.instance,
        builder: (context, child) {
          final favourites = FavouriteService.instance.items;

          if (favourites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.favorite_border,
                    size: 90,
                    color: Colors.red,
                  ),

                  SizedBox(height: 20),

                  Text(
                    "No Favourite Products",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Tap ❤️ on any product to add it here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favourites.length,
            itemBuilder: (context, index) {

              final item = favourites[index];

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            modelNo: item.modelNo,
            imageUrl: item.imageUrl,
          ),
        ),
      );
    },
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            item.imageUrl,
            width: 85,
            height: 85,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text(
                item.modelNo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Tap to View",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

            ],
          ),
        ),

        const Icon(
          Icons.chevron_right,
          color: Colors.red,
          size: 32,
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
    );
  }
}