import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Supabase
import '../components/CustomBottomNavBar.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  File? _imageFile;
  String? _profileImageUrl; // 🔥 Firestore image URL
  final picker = ImagePicker();

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
      setState(() {
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        _profileImageUrl = data['photoUrl'];
      });
    }
  }

  /// ✅ Pick image from gallery
  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(String uid, File file) async {
  final fileName = "profile_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";

  try {
    print("🚀 Trying upload: $fileName");

    await Supabase.instance.client.storage
        .from('profile_pics')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

    final publicUrl = Supabase.instance.client.storage
        .from('profile_pics')
        .getPublicUrl(fileName);

    print("✅ Upload success, public URL: $publicUrl");
    return publicUrl;
  } catch (e) {
    print("❌ Upload error: $e");
    return null;
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
      // Upload new image if selected
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _uploadImage(uid, _imageFile!);
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name,
        'email': email,
        'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl, // update only if new
      });

      _showDialog("Saved!", "Your profile has been updated.", onOk: () {
        Navigator.pop(context);
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
    setState(() => _selectedIndex = index);

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
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Edit Profile",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal[100],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null) as ImageProvider?,
                      child: _imageFile == null && _profileImageUrl == null
                          ? Icon(Icons.person,
                              size: 50, color: Colors.teal[700])
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, color: Colors.teal),
                    label: Text(
                      "Change Profile Picture",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel("Full Name"),
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(hintText: 'Enter your full name'),
            ),
            const SizedBox(height: 20),
            _buildLabel("Email"),
            TextField(
              controller: emailController,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'Your email',
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