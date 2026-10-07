import 'dart:ui';
import 'package:flutter/material.dart';
import 'widgets/pressable.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contact Us — luxury showroom theme.
///
/// UI-only redesign. All contact data, URLs and launch actions
/// are unchanged.
class ContactUsScreen extends StatelessWidget {
  ContactUsScreen({super.key});

  final String phone = "9875174988";
  final String email = "dnenterprise05@gmail.com";
  final String website = "https://electrahardware.com";
  final String maps =
      "https://maps.app.goo.gl/6Z1pemkuJKjrMKs49";

  static const _gold = Color(0xFFD8B36A);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
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
                          "CONTACT US",
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // Address starts below the background
                        // Electra Hardware logo.
                        const SizedBox(height: 150),
                        _glassCard(
                          icon: Icons.location_on_outlined,
                          title: "Address",
                          child: const Text(
                            "PATEL NAGAR, 50 FEET MAIN ROAD\n"
                            "NEAR STAR PACK, RAJKOT (GJ) - 360002",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: _ivory,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _glassCard(
                          icon: Icons.support_agent_outlined,
                          title: "Customer Care",
                          child: const Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      "+91 98751 74988",
                                      style: TextStyle(
                                          color: _ivory,
                                          fontSize: 15),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "+91 90811 74988",
                                      style: TextStyle(
                                          color: _ivory,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      "+91 98241 74988",
                                      style: TextStyle(
                                          color: _ivory,
                                          fontSize: 15),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "+91 95861 74988",
                                      style: TextStyle(
                                          color: _ivory,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _glassCard(
                          icon: Icons.email_outlined,
                          title: "Email",
                          child: const Text(
                            "dnenterprise05@gmail.com",
                            style: TextStyle(
                                fontSize: 15,
                                color: _ivory),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _glassCard(
                          icon: Icons.language_outlined,
                          title: "Website",
                          child: const Text(
                            "www.electrahardware.com",
                            style: TextStyle(
                                fontSize: 15,
                                color: _ivory),
                          ),
                        ),
                        const Spacer(),
                        const Center(
                          child: Text(
                            "Connect With Us",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            _socialIcon(
                              Icons.call,
                              () => openUrl("tel:$phone"),
                            ),
                            _socialImage(
                              "assets/icons/whatsapp.png",
                              () => openUrl(
                                "https://api.whatsapp.com/send?phone=919875174988",
                              ),
                            ),
                            _socialIcon(
                              Icons.location_on,
                              () => openUrl(maps),
                            ),
                            _socialIcon(
                              Icons.language,
                              () => openUrl(website),
                            ),
                            _socialImage(
                              "assets/icons/instagram.png",
                              () => openUrl(
                                "https://www.instagram.com/_electra_hardware_?igsh=ZDNvdnh0MDMxazk0",
                              ),
                            ),
                            _socialImage(
                              "assets/icons/facebook.png",
                              () => openUrl(
                                "https://www.facebook.com/share/163JTqiWc2/",
                              ),
                            ),
                            _socialImage(
                              "assets/icons/youtube.png",
                              () => openUrl(
                                "https://youtube.com/@electrahardware?si=N1L73wJNTo4fxrbK",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _glassCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.10),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: _gold, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _ivory,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _socialIcon(
      IconData icon, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _gold.withValues(alpha: 0.4),
          ),
        ),
        child: Icon(icon, color: _gold, size: 22),
      ),
    );
  }

  static Widget _socialImage(
      String asset, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _gold.withValues(alpha: 0.4),
          ),
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
                Icons.error, color: _gold, size: 20);
          },
        ),
      ),
    );
  }
}
