import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/CustomBottomNavBar.dart';
import '../helpers/tflite_helper.dart';
import 'results.dart';

class AnalyzeScreen extends StatefulWidget {
  final File imageFile;
  const AnalyzeScreen({super.key, required this.imageFile});

  @override
  _AnalyzeScreenState createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  int _selectedIndex = 2;
  late File _imageFile;
  final TFLiteHelper _tfliteHelper = TFLiteHelper();
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isModelLoaded = false;
  String _analysisStatus = '';

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      setState(() => _analysisStatus = 'Loading AI model...');
      await _tfliteHelper.loadModel();

      if (_tfliteHelper.isLoaded && mounted) {
        setState(() {
          _isModelLoaded = true;
          _analysisStatus = 'Model ready! Tap Analyze to start.';
        });
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
    }
  }

  Future<void> _analyzeImage() async {
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
      final modelOutput = await _tfliteHelper.runModel(_imageFile);

      // Check if analysis succeeded
      if (modelOutput['success'] != true) {
        throw Exception(modelOutput['error'] ?? 'Analysis failed');
      }

      // Extract detections
      final detections =
          modelOutput['detections'] as List<Map<String, dynamic>>;
      final inferenceTime = modelOutput['inferenceTime'] as int;

      // Find best detection (highest confidence)
      if (detections.isEmpty) {
        throw Exception('No objects detected in image');
      }

      // Get the detection with highest confidence
      detections.sort(
        (a, b) =>
            (b['confidence'] as double).compareTo(a['confidence'] as double),
      );

      final bestDetection = detections.first;
      final bestLabel = bestDetection['class'] as String;
      final confidenceValue = bestDetection['confidence'] as double;
      final confidence = confidenceValue.toStringAsFixed(2);

      // Calculate probabilities for all classes
      Map<String, double> allProbs = {
        'Possible Dehydrated': 0.0,
        'Normal': 0.0,
        'Possible UTI': 0.0,
      };

      // Aggregate confidences by class
      for (var detection in detections) {
        final className = detection['class'] as String;
        final conf = detection['confidence'] as double;
        if (allProbs.containsKey(className)) {
          allProbs[className] = allProbs[className]! + conf;
        }
      }

      // Normalize to 100%
      final total = allProbs.values.reduce((a, b) => a + b);
      if (total > 0) {
        allProbs.forEach((key, value) {
          allProbs[key] = (value / total) * 100;
        });
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

      setState(() => _analysisStatus = 'Saving to database...');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Save to Firebase analysis_results
      await FirebaseFirestore.instance.collection('analysis_results').add({
        'userId': user.uid,
        'timestamp': Timestamp.now(),
        'result': bestLabel,
        'confidence': confidence,
        'allProbabilities': {
          'dehydrated': allProbs['Possible Dehydrated']!.toStringAsFixed(2),
          'normal': allProbs['Normal']!.toStringAsFixed(2),
          'uti': allProbs['Possible UTI']!.toStringAsFixed(2),
        },
        'inferenceTime': inferenceTime,
        'imageUrl': imageUrl,
        'detectionsCount': detections.length,
        'segmentationEnabled': true,
      });

      // Save to history collection
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

      setState(() => _analysisStatus = 'Analysis complete!');

      // Navigate to results
      if (mounted) {
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
      }
    } catch (e) {
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
              onPressed: _analyzeImage,
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

  @override
  void dispose() {
    _tfliteHelper.close();
    super.dispose();
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
                      : _analyzeImage,
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
                    foregroundColor: Colors.white,
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
                      'The AI will analyze the image using instance segmentation and provide results. Make sure the image is clear and well-lit for best accuracy.',
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
