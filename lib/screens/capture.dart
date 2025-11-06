import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../components/app_drawer.dart';
import '../components/CustomBottomNavBar.dart';
import 'symptoms.dart';

class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  int _selectedIndex = 2;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // ✅ Capture image from camera
  Future<void> _captureImage() async {
    final XFile? captured = await _picker.pickImage(source: ImageSource.camera);
    if (captured == null) return;

    final File imageFile = File(captured.path);
    bool blurry = await compute(_checkBlur, imageFile.path);

    if (blurry) {
      _showBlurDialog();
    } else {
      setState(() => _image = imageFile);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SymptomsScreen(imageFile: imageFile),
        ),
      );
    }
  }

  // ✅ Upload image from gallery
  Future<void> _uploadImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final File imageFile = File(picked.path);
    bool blurry = await compute(_checkBlur, imageFile.path);

    if (blurry) {
      _showBlurDialog();
    } else {
      setState(() => _image = imageFile);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SymptomsScreen(imageFile: imageFile),
        ),
      );
    }
  }

  // ✅ Optimized blur detection (background isolate)
  static bool _checkBlur(String path) {
    try {
      final file = File(path);
      final bytes = file.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return true;

      // Resize to make analysis 5–10x faster
      final resized = img.copyResize(image, width: 256);
      final gray = img.grayscale(resized);

      double sum = 0, sumSq = 0;
      int count = 0;

      for (int y = 1; y < gray.height - 1; y++) {
        for (int x = 1; x < gray.width - 1; x++) {
          final gx =
              img.getLuminance(gray.getPixel(x + 1, y)) -
              img.getLuminance(gray.getPixel(x - 1, y));
          final gy =
              img.getLuminance(gray.getPixel(x, y + 1)) -
              img.getLuminance(gray.getPixel(x, y - 1));
          final v = (gx * gx + gy * gy).toDouble();
          sum += v;
          sumSq += v * v;
          count++;
        }
      }

      final mean = sum / count;
      final variance = (sumSq / count) - (mean * mean);

      // Lower threshold slightly for more accurate detection
      return variance < 5000;
    } catch (e) {
      debugPrint("Error checking blur: $e");
      return true;
    }
  }

  void _showBlurDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Image too blurry"),
        content: const Text("Please retake or choose a clearer image."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
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
        automaticallyImplyLeading: true,
        backgroundColor: Colors.teal,
        title: Text(
          'Capture Sample',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 800;
          final double contentWidth = isWide
              ? 500
              : constraints.maxWidth * 0.85;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _image == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 100,
                            color: Colors.grey,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _image!,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                    const SizedBox(height: 20),
                    Text(
                      'Tap a button below to capture or upload an image of your urine sample.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isWide ? 18 : 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera),
                            label: Text(
                              'Capture',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            onPressed: _captureImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (isWide) const SizedBox(width: 20),
                        if (isWide)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: Text(
                                'Upload Image',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              onPressed: _uploadImage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                side: const BorderSide(color: Colors.teal),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!isWide) const SizedBox(height: 20),
                    if (!isWide)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            'Upload Image',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          onPressed: _uploadImage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
