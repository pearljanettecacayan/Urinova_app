import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/app_drawer.dart';
import '../components/CustomBottomNavBar.dart';
import 'package:urinalysis_app/helpers/tflite_helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? userName; // 👤 store first name from Firestore

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

  final List<Map<String, String>> history = [
    {"date": "Sept 28, 2025", "result": "Normal"},
    {"date": "Sept 25, 2025", "result": "Slight Dehydration"},
    {"date": "Sept 20, 2025", "result": "Normal"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    TFLiteHelper().loadModel(); // Load model once at app start
  }


  // 🔍 Fetch first name from Firestore
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
          // ✂️ Extract first name (before the first space)
          final firstName = fullName.split(' ').first;
          setState(() {
            userName = firstName;
          });
        } else {
          // fallback if no Firestore document found
          setState(() {
            userName = user.email?.split('@').first ?? 'User';
          });
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() {
        userName = 'User';
      });
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
            // 👋 Greeting Section
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

            // 🖼️ Carousel Slider
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

            const SizedBox(height: 24),

          
            // 📰 Articles
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
                  leading: Icon(Icons.article, color: Colors.teal),
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

  // 📊 Reusable Stat Card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
