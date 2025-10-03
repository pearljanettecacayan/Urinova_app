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

  // ✅ Dummy history data
  final List<Map<String, String>> history = [
    {"date": "Sept 28, 2025", "result": "Normal"},
    {"date": "Sept 25, 2025", "result": "Slight Dehydration"},
    {"date": "Sept 20, 2025", "result": "Normal"},
  ];

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
        Navigator.pushReplacementNamed(context, '/notifications'); // 🔔
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
            // ✅ Greeting
            Text(
              "Hello, Pearl !",
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

            // ✅ Health Summary Section
            Text(
              "Your Health Summary",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  "Hydration",
                  "75%",
                  Icons.water_drop,
                  Colors.blue,
                ),
                _buildStatCard(
                  "Last Scan",
                  "Normal",
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  "UTI Risk",
                  "Low",
                  Icons.health_and_safety,
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ✅ History Section
            Text(
              "Recent History",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),
            ...history.map((entry) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.history, color: Colors.teal),
                  title: Text(
                    entry["date"]!,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Result: ${entry["result"]!}",
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/history',
                    ); // ✅ go to history page
                  },
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // ✅ Articles Section
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

  // ✅ Reusable Stat Card
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
