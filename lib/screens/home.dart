import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/app_drawer.dart';
import '../components/CustomBottomNavBar.dart';
import 'package:urinalysis_app/helpers/tflite_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? userName;

  final List<Map<String, String>> articles = [
    {
      "title": "Frequent Urination",
      "content":
          "One of the most common UTI symptoms is feeling the need to urinate more often than usual, even when little urine comes out. This happens because bacteria irritate the bladder lining.",
    },
    {
      "title": "Burning Sensation During Urination",
      "content":
          "A painful, burning feeling when urinating is a classic UTI symptom. This occurs due to inflammation in the urinary tract caused by bacterial infection.",
    },
    {
      "title": "Cloudy or Strong-Smelling Urine",
      "content":
          "UTI can cause urine to appear cloudy, murky, or have an unusually strong, unpleasant odor. This is often due to the presence of bacteria, pus, or blood in the urine.",
    },
    {
      "title": "Lower Abdominal or Pelvic Pain",
      "content":
          "Many people with UTI experience discomfort, pressure, or cramping in the lower abdomen or pelvic area. This pain may worsen when urinating or after emptying the bladder.",
    },
    {
      "title": "Blood in Urine (Hematuria)",
      "content":
          "Urine that appears pink, red, or cola-colored may indicate blood presence, a serious UTI symptom. If you notice blood in your urine, seek medical attention immediately.",
    },
    {
      "title": "Feeling of Incomplete Bladder Emptying",
      "content":
          "UTI can create a persistent feeling that your bladder is not completely empty even right after urination. This uncomfortable sensation is caused by bladder inflammation.",
    },
    {
      "title": "Fever and Chills",
      "content":
          "When UTI spreads to the kidneys, it may cause fever, chills, nausea, and back pain. These are signs of a more serious infection requiring immediate medical attention.",
    },
    {
      "title": "Dehydration Symptoms",
      "content":
          "Signs of dehydration include excessive thirst, dry mouth, dizziness, fatigue, and dark yellow urine. Severe dehydration can cause confusion, rapid heartbeat, and decreased urination. Stay hydrated and seek medical help if symptoms persist.",
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
                      color: Colors.teal[800],
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              "Welcome to Urinova! Here's your health overview today.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // Image Carousel
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

            // Introduction Section
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
                title: Text("Introduction", style: GoogleFonts.poppins()),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "The color of urine is a vital indicator of hydration levels and potential infections, making urinalysis an essential tool in health monitoring. However, traditional urinalysis methods often require clinical or hospital visits, posing challenges for continuous monitoring, especially for individuals in remote areas and those with mobility impairments.",
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
                          "The healthcare and medical field is one of the many industries that have seen considerable change due to the quick development of mobile technology and artificial intelligence (AI). Innovative technologies that improve the accuracy and efficiency of illness identification and monitoring have been established by integrating AI-assisted image processing into medical diagnostics.",
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
                        Text(
                          "Smart-assisted AI urinalysis is one prominent use of this technology that decreases the need for frequent clinical visits and increases accessibility to necessary health screenings by allowing people to perform routine urine tests at home. Recent studies have explored the feasibility of smartphone-based urinalysis using AI-powered image recognition techniques.",
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
                        Text(
                          "Smartphone cameras can be used to detect color changes, transforming them into reliable diagnostic tools for UTI detection. By applying comprehensive color normalization techniques, smartphone-based systems can correct for variations in lighting and device hardware, making it possible to obtain accurate color readings even in uncontrolled environments.",
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
                        Text(
                          "These systems image urine with a smartphone camera and use machine-learning algorithms to identify UTI and dehydration-associated biomarkers. This innovative approach enables early screening using only a smartphone camera, making health monitoring more accessible and affordable for communities without laboratory access.",
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            //System Overview & Limitations section
            _buildSection(
              title: "System Overview & Limitations",
              content: [
                "This AI-powered system analyzes urine color and turbidity from captured images for preliminary screening of possible UTI indicators and dehydration, without requiring chemical strips.",
                "Designed with user accessibility in mind, the mobile application features an intuitive interface suitable for elderly and non-tech-savvy users, with minimal input requirements and integration capabilities for healthcare platforms.",
                "Limitations:",
                "Image Quality: Accuracy depends on smartphone camera quality, lighting conditions, and image capture quality.",
                "Diagnostic Scope: Focuses only on visual analysis of urine color and turbidity. Does not replace laboratory tests or medical consultations.",
                "Device Compatibility: Performance may vary across different smartphone models due to camera quality and processing power differences.",
                "Semi-Automation: Urine collection and image capture are manual processes performed by users.",
                "External Factors: Does not account for medications, diet, or menstrual cycle that may affect urine color.",
                "Despite these limitations, this study contributes to AI-powered health screening by improving accessibility, efficiency, and early health awareness.",
                "Disclaimer: This is a preliminary screening tool only. Seek professional medical attention for confirmation, diagnosis, and treatment of any abnormal results or symptoms.",
              ],
            ),

            const SizedBox(height: 24),

            // Sypmtoms
            Text(
              "Symptoms",
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
            }),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // 🔹 Reusable Section
  Widget _buildSection({
    required String title,
    IconData? icon,
    required List<String> content,
    String? image,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ExpansionTile(
        leading: icon != null ? Icon(icon, color: Colors.teal) : null,
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
