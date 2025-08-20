import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/CustomBottomNavBar.dart'; 

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController(text: 'Momai User');
  final TextEditingController emailController = TextEditingController(text: 'momai@example.com');
  final TextEditingController phoneController = TextEditingController(text: '09XXXXXXXXX');

  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation logic
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/capture');
        break;
      case 2:
        Navigator.pushNamed(context, '/instructions');
        break;
      case 3:
        // Already on edit profile
        break;
    }
  }

  void _saveChanges() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Saved!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Your profile has been updated.", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text("OK", style: GoogleFonts.poppins()),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pop(context); // Back to profile screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Edit Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.teal[100],
              child: Icon(Icons.person, size: 50, color: Colors.teal[700]),
            ),
            SizedBox(height: 24),
            _buildLabel("Full Name"),
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'Enter your full name'),
            ),
            SizedBox(height: 20),
            _buildLabel("Email"),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: 'Enter your email'),
            ),
            SizedBox(height: 20),
            _buildLabel("Phone Number"),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(hintText: 'Enter your phone number'),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("Save Changes", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
