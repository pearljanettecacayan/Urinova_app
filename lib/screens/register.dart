import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _loading = false;

  // state for toggle password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showAlert('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showAlert('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    try {
      // Create user in Firebase Auth
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save extra user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showAlert('Account created successfully!', onOk: () {
        Navigator.pushNamed(context, '/introduction');
      });
    } on FirebaseAuthException catch (e) {
      _showAlert(e.message ?? 'Registration failed.');
    } catch (e) {
      _showAlert('An error occurred: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showAlert(String message, {VoidCallback? onOk}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notice',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk?.call();
            },
            child: Text('OK', style: GoogleFonts.poppins(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // full width
        height: double.infinity, // full height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Register to start using URINOVA.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(
                        'Full Name',
                        'Enter your full name',
                        nameController,
                      ),
                      _buildTextField(
                        'Email',
                        'Enter your email',
                        emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        'Phone Number',
                        'Enter your phone number',
                        phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        'Password',
                        'Create a password',
                        passwordController,
                        obscureText: _obscurePassword,
                        toggleObscure: () {
                          setState(() =>
                              _obscurePassword = !_obscurePassword);
                        },
                      ),
                      _buildTextField(
                        'Confirm Password',
                        'Re-enter your password',
                        confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        toggleObscure: () {
                          setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword);
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  'Create Account',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Back to Login',
                            style:
                                GoogleFonts.poppins(color: Colors.teal[700]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // modified _buildTextField with toggle support
  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? toggleObscure,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14)),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              suffixIcon: toggleObscure == null
                  ? null
                  : IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: toggleObscure,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
