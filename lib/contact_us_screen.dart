import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  ContactUsScreen({super.key});

  final String phone = "9875174988";
  final String email = "dnenterprise05@gmail.com";
  final String website = "https://electrahardware.com";
  final String maps =
      "https://maps.app.goo.gl/6Z1pemkuJKjrMKs49";

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
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [

              Image.asset(
                "assets/logo.png",
                width: 160,
              ),

              const SizedBox(height: 12),

              const Text(
  "Manufacturer & Exporter of Premium Hardware Products",
  textAlign: TextAlign.center,
  maxLines: 1,
overflow: TextOverflow.visible,
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  ),
),

              const SizedBox(height: 25),
                            Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Address",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      const Text(
  "PATEL NAGAR, 50 FEET MAIN ROAD\n"
  "NEAR STAR PACK, RAJKOT (GJ) - 360002",
  style: TextStyle(
    fontSize: 16,
    height: 1.5,
  ),
),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Customer Care",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

Row(
  children: [

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [

          Text("+91 98751 74988"),

          SizedBox(height: 12),

          Text("+91 90811 74988"),

        ],
      ),
    ),

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [

          Text("+91 98241 74988"),

          SizedBox(height: 12),

          Text("+91 95861 74988"),

        ],
      ),
    ),

  ],
),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
                            Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Email",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      Text(
                        "dnenterprise05@gmail.com",
                        style: TextStyle(fontSize: 16),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Icon(
                            Icons.language,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Website",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      Text(
                        "www.electrahardware.com",
                        style: TextStyle(fontSize: 16),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Divider(),

const SizedBox(height: 15),

const Text(
  "Connect With Us",
  style: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black54,
  ),
),

const SizedBox(height: 15),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [

    GestureDetector(
      onTap: () => openUrl("tel:$phone"),
      child: const Icon(
        Icons.call,
        color: Colors.red,
        size: 28,
      ),
    ),

    GestureDetector(
      onTap: () => openUrl(
        "https://api.whatsapp.com/send?phone=919875174988",
      ),
      child: SizedBox(
  width: 30,
  height: 30,
  child: Image.asset(
    "assets/icons/whatsapp.png",
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) {
      return const Icon(Icons.error, color: Colors.red);
    },
  ),
),
    ),

    GestureDetector(
      onTap: () => openUrl(maps),
      child: Icon(
  Icons.location_on,
  color: Colors.blue,
  size: 28,
),
    ),

    GestureDetector(
      onTap: () => openUrl(website),
      child: const Icon(
        Icons.language,
        color: Colors.black87,
        size: 28,
      ),
    ),

    GestureDetector(
      onTap: () => openUrl(
        "https://www.instagram.com/_electra_hardware_?igsh=ZDNvdnh0MDMxazk0",
      ),
      child: Image.asset(
  "assets/icons/instagram.png",
  width: 26,
  height: 26,
),
    ),

    GestureDetector(
      onTap: () => openUrl(
        "https://www.facebook.com/share/163JTqiWc2/",
      ),
      child: Image.asset(
  "assets/icons/facebook.png",
  width: 26,
  height: 26,
),
    ),

    GestureDetector(
      onTap: () => openUrl(
        "https://youtube.com/@electrahardware?si=N1L73wJNTo4fxrbK",
      ),
      child: Image.asset(
  "assets/icons/youtube.png",
  width: 26,
  height: 26,
),
    ),

  ],
),

const SizedBox(height: 20),
                          ],
          ),
        ),
      ),
    );
  }
}