import 'dart:ui';
import 'package:flutter/material.dart';
import 'services/favourite_service.dart';
import 'product_details_screen.dart';

/// Favourite — luxury showroom theme.
///
/// UI-only redesign. Favourite list, product navigation and
/// remove functionality are unchanged. Product photos are
/// displayed exactly as provided.
class FavouriteScreen extends StatelessWidget {
  FavouriteScreen({super.key});

  static const _gold = Color(0xFFD8B36A);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

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
                          "FAVOURITE",
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
                  child: AnimatedBuilder(
                    animation: FavouriteService.instance,
                    builder: (context, child) {
                      final favourites =
                          FavouriteService.instance.items;

                      if (favourites.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 72,
                                color: _gold,
                              ),
                              SizedBox(height: 18),
                              Text(
                                "No Favourite Products",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: _ivory,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Tap the heart on any product to add it here.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            20, 8, 20, 24),
                        itemCount: favourites.length,
                        itemBuilder: (context, index) {
                          final item = favourites[index];

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              border: Border.all(
                                color: _gold.withValues(
                                    alpha: 0.35),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 2.5,
                                    sigmaY: 2.5),
                                child: Container(
                                  color: Colors.black
                                      .withValues(
                                          alpha: 0.10),
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius
                                            .circular(14),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductDetailsScreen(
                                            modelNo:
                                                item.modelNo,
                                            imageUrl: item
                                                .imageUrl,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets
                                              .all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .center,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                                        10),
                                            child:
                                                Image.network(
                                              item.imageUrl,
                                              width: 85,
                                              height: 85,
                                              fit: BoxFit
                                                  .cover,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                              children: [
                                                Text(
                                                  item
                                                      .modelNo,
                                                  style:
                                                      const TextStyle(
                                                    fontSize:
                                                        17,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                    color:
                                                        _ivory,
                                                    letterSpacing:
                                                        0.4,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height:
                                                        6),
                                                const Text(
                                                  "Tap to View",
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        _muted,
                                                    fontSize:
                                                        13.5,
                                                    fontWeight:
                                                        FontWeight
                                                            .w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: _gold
                                                .withValues(
                                                    alpha:
                                                        0.8),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
