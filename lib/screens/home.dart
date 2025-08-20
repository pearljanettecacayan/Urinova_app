import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../components/app_drawer.dart';
import '../components/CustomBottomNavBar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, String>> articles = [
    {
      "title": "Understanding Urine Color: What It Means",
      "content":
          "Urine color can indicate your hydration and health. Light yellow usually means well-hydrated, dark yellow can suggest dehydration, while red or cloudy urine may signal possible infection or other health issues.",
    // "image": "assets/images/urine_color.jpg"
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

  // ✅ List of image assets for carousel
  final List<String> carouselImages = [
    "assets/images/urine_img.png",
    "assets/images/urine.png",
    "assets/images/urine_img.png",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Home
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/instructions');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/capture');
        break;
      case 3:
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
          'Home',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Carousel Slider at the top
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
}
