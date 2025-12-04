import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/CustomBottomNavBar.dart';
import '../helpers/tflite_helper.dart';
import 'results.dart';

class SymptomsScreen extends StatefulWidget {
  final File imageFile;
  const SymptomsScreen({super.key, required this.imageFile});

  @override
  _SymptomsScreenState createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  int _selectedIndex = 2;
  late File _imageFile;
  final TFLiteHelper _tfliteHelper = TFLiteHelper();
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isModelLoaded = false;

  // Analysis progress tracking
  String _analysisStatus = '';

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
    _loadModelInBackground();
  }

  void _loadModelInBackground() async {
    try {
      setState(() => _analysisStatus = 'Loading AI model...');
      await _tfliteHelper.loadModel();

      if (_tfliteHelper.isLoaded) {
        if (mounted) {
          setState(() {
            _isModelLoaded = true;
            _analysisStatus = 'Model ready! Tap Analyze to start.';
          });
          print('Model loaded successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analysisStatus = 'Model load failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Model loading error: $e');
    }
  }

  Future<void> _analyzeSymptoms() async {
    if (!_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for model to load'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verify file exists
      if (!await _imageFile.exists()) {
        throw Exception('Image file not found!');
      }

      setState(() => _analysisStatus = 'Running AI analysis...');

      // Run model inference
      List<double> results = await tflite_helper.runModel(_imageFile);

      if (results.isEmpty) {
        throw Exception("Model returned empty results");
      }

      print('Model output: $results');

      // Define labels (must match your model's training labels)
      final labels = ['Possible Dehydrated', 'Normal', 'Possible UTI'];

      // Get prediction with highest confidence
      final bestIndex = results.indexOf(
        results.reduce((a, b) => a > b ? a : b),
      );
      final bestLabel = labels[bestIndex];
      final confidence = (results[bestIndex] * 100).toStringAsFixed(2);

      print('Prediction: $bestLabel (${confidence}% confidence)');
      print('All probabilities:');
      for (int i = 0; i < labels.length; i++) {
        print('   ${labels[i]}: ${(results[i] * 100).toStringAsFixed(2)}%');
      }

      // Warn if confidence is low
      final confidenceValue = results[bestIndex] * 100;

      String warningTitle = '';
      String warningMessage = '';

      if (confidenceValue < 40) {
        // Very low confidence - likely wrong image
        warningTitle = 'Invalid Sample Detected';
        warningMessage =
            'The AI is only ${confidence}% confident. '
            'This does not appear to be a urine sample. '
            'Please capture a proper urine sample for accurate results.';
      } else if (confidenceValue < 60) {
        // Low confidence - quality or lighting issue
        warningTitle = 'Low Confidence Warning';
        warningMessage =
            'The AI is only ${confidence}% confident. '
            'Image quality may be poor or lighting conditions are not optimal. '
            'Consider retaking the photo with better lighting and focus.';
      }

      // Show warning dialog if confidence is below threshold
      if (confidenceValue < 60) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              warningTitle,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: confidenceValue < 40 ? Colors.red : Colors.orange,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  confidenceValue < 40 ? Icons.error : Icons.warning,
                  color: confidenceValue < 40 ? Colors.red : Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(warningMessage, style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to capture screen
                },
                child: Text(
                  'Retake Photo',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (confidenceValue >=
                  40) // Only show "Continue" if not extremely low
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Continue Anyway',
                    style: GoogleFonts.poppins(color: Colors.teal),
                  ),
                ),
            ],
          ),
        );

        // If very low confidence and user clicked retake, stop here
        if (confidenceValue < 40) {
          setState(() => _isLoading = false);
          return;
        }
      }

      setState(() => _analysisStatus = 'Uploading results...');

      // Upload image to Supabase
      final fileName = 'urine_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bucketName = 'urine_images';

      await supabase.storage
          .from(bucketName)
          .upload(
            fileName,
            _imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);
      print('Image uploaded: $imageUrl');

      setState(() => _analysisStatus = 'Saving to database...');

      // Save to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Save detailed analysis results
      await FirebaseFirestore.instance.collection('analysis_results').add({
        'userId': user.uid,
        'timestamp': Timestamp.now(),
        'result': bestLabel,
        'confidence': confidence,
        'allProbabilities': {
          'dehydrated': (results[0] * 100).toStringAsFixed(2),
          'normal': (results[1] * 100).toStringAsFixed(2),
          'uti': (results[2] * 100).toStringAsFixed(2),
        },
        'imageUrl': imageUrl,
      });

      // Save to history (simplified version)
      final historyRef = FirebaseFirestore.instance.collection('history');
      final existing = await historyRef
          .where('userId', isEqualTo: user.uid)
          .where('imageUrl', isEqualTo: imageUrl)
          .get();

      if (existing.docs.isEmpty) {
        // Map results to hydration and UTI risk
        String hydrationResult;
        String utiRisk;

        if (bestLabel == 'Possible Dehydrated') {
          hydrationResult = 'Possible Dehydrated';
          utiRisk = 'Low';
        } else if (bestLabel == 'Possible UTI') {
          hydrationResult = 'Normal';
          utiRisk = 'High';
        } else {
          hydrationResult = 'Normal';
          utiRisk = 'Low';
        }

        await historyRef.add({
          'userId': user.uid,
          'hydration': hydrationResult,
          'utiRisk': utiRisk,
          'imageUrl': imageUrl,
          'date': Timestamp.now(),
        });
      }

      print('Results saved successfully');
      setState(() => _analysisStatus = 'Analysis complete!');

      // Navigate to results screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            hydrationResult: bestLabel == 'Normal' ? 'Normal' : bestLabel,
            utiRisk: bestLabel == 'Possible UTI' ? 'High' : 'Low',
            confidence: confidence,
          ),
        ),
      );
    } catch (e) {
      print('Analysis error: $e');

      setState(() {
        _analysisStatus = 'Analysis failed';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _analyzeSymptoms,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
  void dispose() {
    _tfliteHelper.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Urinova Analysis',
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
            // Title
            Text(
              "Captured Urine Image",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),

            // Image Preview
            Center(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),

                  // Model Ready Badge
                  if (_isModelLoaded)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ready',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status Message
            if (_analysisStatus.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _analysisStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Analyze Button
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: (!_isModelLoaded || _isLoading)
                      ? null
                      : _analyzeSymptoms,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(
                    _isLoading
                        ? "Analyzing..."
                        : (_isModelLoaded ? "Analyze" : "Loading Model..."),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The AI will analyze the image and provide results. Make sure the image is clear and well-lit for best accuracy.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
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
}
