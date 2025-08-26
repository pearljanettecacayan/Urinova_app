import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/CustomBottomNavBar.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  int _selectedIndex = 3;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Load user data from Firestore
  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phone'] ?? '';
    }
  }

  /// ✅ Save changes to Firestore
  Future<void> _saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      _showDialog("Error", "Please fill in all fields.");
      return;
    }

    setState(() => _loading = true);

    try {
      // Update Firestore only
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name,
        'email': email,
        'phone': phone,
      });

      _showDialog("Saved!", "Your profile has been updated.", onOk: () {
        Navigator.pop(context); // ✅ balik sa Profile screen
      });
    } catch (e) {
      _showDialog("Error", "Failed to update profile: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showDialog(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text("OK", style: GoogleFonts.poppins(color: Colors.teal)),
            onPressed: () {
              Navigator.of(context).pop();
              if (onOk != null) onOk();
            },
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/instructions');
        break;
      case 2:
        Navigator.pushNamed(context, '/capture');
        break;
      case 3:
        // already here
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true, // ✅ Para ma-center ang title
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.teal[100],
                child: Icon(Icons.person, size: 50, color: Colors.teal[700]),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel("Full Name"),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Enter your full name'),
            ),
            const SizedBox(height: 20),
            _buildLabel("Email"),
            TextField(
              controller: emailController,
              readOnly: true, // 🔒 Email is read-only
              decoration: const InputDecoration(
                hintText: 'Your email',
                filled: true,
                fillColor: Color(0xFFF0F0F0), // light grey background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildLabel("Phone Number"),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(hintText: 'Enter your phone number'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Save Changes",
                        style: GoogleFonts.poppins(
                            fontSize: 18, color: Colors.white)),
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
        style:
            GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}