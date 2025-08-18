import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/app_drawer.dart';
import '../components/CustomBottomNavBar.dart'; // <-- Import this!

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String fullName = 'Momai User';
  final String email = 'momai@example.com';
  final String phoneNumber = '+63 912 345 6789';

  int _selectedIndex = 3; // Profile tab

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
        // Already on profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.teal, // <--- TEAL COLOR
        title: const Text('Profile', style: TextStyle(color: Colors.white),),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // drawer icon color
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.teal[100],
              child: Icon(Icons.person, size: 60, color: Colors.teal[700]),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                email,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                phoneNumber,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/editProfile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Info',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ✅ Use CustomBottomNavBar
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
