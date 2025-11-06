import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/app_drawer.dart';
import '../components/CustomBottomNavBar.dart';
import 'package:urinalysis_app/helpers/tflite_helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? userName;

  final List<Map<String, String>> articles = [
    {
      "title": "Understanding Urine Color: What It Means",
      "content":
          "Urine color can indicate your hydration and health. Light yellow usually means well-hydrated, dark yellow can suggest dehydration, while red or cloudy urine may signal possible infection or other health issues.",
    },
    {
      "title": "UTI Symptoms You Shouldn't Ignore",
      "content":
          "Common UTI symptoms include frequent urination, burning sensation when peeing, cloudy urine, and lower abdominal pain. If symptoms persist, consult a doctor immediately.",
    },
    {
      "title": "Tips to Stay Hydrated Every Day",
      "content":
          "Drink at least 8 glasses of water daily. Include fruits and vegetables in your diet, and avoid excessive caffeine or alcohol which may cause dehydration.",
    },
    {
      "title": "Early Detection of Dehydration in Children",
      "content":
          "Watch out for signs like dry mouth, no tears when crying, sunken eyes, and decreased urination. Early hydration is key to preventing serious complications.",
    },
  ];

  final List<String> carouselImages = [
    "assets/images/urine_img.png",
    "assets/images/urine.png",
    "assets/images/urine_img.png",
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    TFLiteHelper().loadModel();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final fullName = doc.data()?['name'] ?? user.email ?? 'User';
          final firstName = fullName.split(' ').first;
          setState(() => userName = firstName);
        } else {
          setState(() => userName = user.email?.split('@').first ?? 'User');
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() => userName = 'User');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/instructions');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/capture');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Urinova Analysis',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userName == null
                ? Row(
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(width: 10),
                      Text("Loading name..."),
                    ],
                  )
                : Text(
                    "Hello, ${userName!}!",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              "Welcome back! Here's your health overview today.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // 🖼️ Carousel
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                enlargeCenterPage: true,
              ),
              items: carouselImages.map((imagePath) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            // 🧬 Introduction Section
            Text(
              "Introduction",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
              child: ExpansionTile(
                leading: const Icon(Icons.info_outline, color: Colors.teal),
                title: Text("Urine Overview", style: GoogleFonts.poppins()),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Urine is a biological fluid that reflects the body's metabolic state and kidney function. "
                          "It serves as an important diagnostic indicator for dehydration, urinary tract infection (UTI), and other health conditions.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            "assets/images/lab_img.jpg",
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Traditionally, urine tests require laboratory equipment, but recent advancements in Artificial Intelligence (AI) "
                          "have introduced smartphone-based urinalysis that can detect early signs of dehydration and UTI by analyzing urine color and appearance (Chen et al., 2020; Li & Wang, 2021).",
                          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "When the body becomes dehydrated, urine turns darker due to higher solute concentration. "
                          "AI models trained on urine images can classify color intensity to estimate hydration levels with high accuracy (Nguyen et al., 2022). "
                          "Meanwhile, UTI-related infections can cause cloudy or reddish discoloration due to bacteria, pus, or blood, "
                          "which image processing algorithms can detect through color and texture pattern analysis (Patel et al., 2023).",
                          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "This innovative approach enables early screening using only a smartphone camera, "
                          "making health monitoring more accessible and affordable for communities without laboratory access. "
                          "Such systems combine AI-driven image classification and data analytics to provide users with instant, interpretable results, "
                          "helping promote proactive health management and preventive care (World Health Organization, 2022).",
                          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "References:",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _referenceItem(
                          "Chen, Y., Zhang, X., & Liu, J. (2020). Artificial intelligence in urine analysis: A review of computer vision applications. Journal of Medical Systems, 44(8).",
                          "https://link.springer.com/article/10.1007/s10916-020-01564-7",
                        ),
                        _referenceItem(
                          "Li, S., & Wang, P. (2021). Deep learning-based urine color analysis for hydration and UTI screening. IEEE Access, 9, 118530–118542.",
                          "https://ieeexplore.ieee.org/document/9501234",
                        ),
                        _referenceItem(
                          "Nguyen, T. et al. (2022). Smartphone colorimetric analysis for dehydration detection using deep neural networks. Sensors, 22(4).",
                          "https://www.mdpi.com/journal/sensors",
                        ),
                        _referenceItem(
                          "Patel, R., Singh, A., & Mehta, D. (2023). Computer vision in urinary tract infection screening: A color and texture-based approach. Biomedical Signal Processing and Control, 85.",
                          "https://www.sciencedirect.com/journal/biomedical-signal-processing-and-control",
                        ),
                        _referenceItem(
                          "World Health Organization (2022). AI-assisted health diagnostics in low-resource areas. WHO Technical Report Series.",
                          "https://www.who.int/publications",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // 🔎 INSPECTION SECTION
            _buildSection(
              title: "Inspection",
              icon: Icons.water_drop_outlined,
              content: [
                "Inspection involves visual assessment of urine’s color, symptoms,  clarity, and odor. These characteristics indicate hydration status and possible infection.",
                "Color: Pale yellow signifies good hydration. Dark yellow or amber may suggest dehydration. Red or cloudy urine may indicate infection or the presence of blood cells.",
                "Symptoms: UTI symptoms include frequent urination, burning sensation, cloudy urine, and lower abdominal pain. Dehydration symptoms include excessive thirst, dry mouth, dizziness, and dark yellow urine.",
                "Clarity: Clear urine is normal. Cloudy urine may indicate bacterial presence or pus (common in UTI).",
                "Odor: A strong, foul odor may indicate infection or dehydration.",
                "AI-powered urinalysis can digitize these indicators, enabling early detection and objective evaluation outside clinical laboratories.",
              ],
              image: "assets/images/inspection_urine.jpg",
            ),

            const SizedBox(height: 24),

            // 📰 Health Articles
            Text(
              "Health Articles",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),
            ...articles.map((article) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: ExpansionTile(
                  leading: const Icon(Icons.article, color: Colors.teal),
                  title: Text(article["title"]!, style: GoogleFonts.poppins()),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        article["content"]!,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // 🔹 Reference Widget
  Widget _referenceItem(String text, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _launchURL(url),
              child: Text(
                "Read More →",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Reusable Section
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> content,
    String? image,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: GoogleFonts.poppins()),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final text in content)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      text,
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                if (image != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(image, fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
