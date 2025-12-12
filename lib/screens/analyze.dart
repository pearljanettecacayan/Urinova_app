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

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _tfliteHelper.loadModel();
      if (_tfliteHelper.isLoaded && mounted) {
        setState(() {
          _isModelLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
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

    setState(() {
      _isLoading = true;
    });

    try {
      if (!await _imageFile.exists()) {
        throw Exception('Image file not found!');
      }

      final modelOutput = await _tfliteHelper.runModel(_imageFile);

      if (modelOutput['success'] != true) {
        throw Exception(modelOutput['error'] ?? 'Analysis failed');
      }

      final detections =
          modelOutput['detections'] as List<Map<String, dynamic>>;
      final inferenceTime = modelOutput['inferenceTime'] as int;

      if (detections.isEmpty) {
        throw Exception(
          'No urine sample detected in image. Please ensure the sample is clearly visible.',
        );
      }

      detections.sort(
        (a, b) =>
            (b['confidence'] as double).compareTo(a['confidence'] as double),
      );

      final bestDetection = detections.first;
      final bestLabel = bestDetection['class'] as String;
      final confidenceValue = bestDetection['confidence'] as double;
      final confidence = confidenceValue.toStringAsFixed(2);

      Map<String, double> allProbs = {
        'Possible Dehydrated': 0.0,
        'Normal': 0.0,
        'Possible UTI': 0.0,
      };

      for (var detection in detections) {
        final className = detection['class'] as String;
        final conf = detection['confidence'] as double;
        if (allProbs.containsKey(className)) {
          allProbs[className] = allProbs[className]! + conf;
        }
      }

      final total = allProbs.values.reduce((a, b) => a + b);
      if (total > 0) {
        allProbs.forEach((key, value) {
          allProbs[key] = (value / total) * 100;
        });
      }

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

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

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
        'polygonPoints': bestDetection['polygon']?.length ?? 0,
      });

      String hydrationResult;
      String utiRisk;

      if (bestLabel == 'possible dehydrated') {
        hydrationResult = 'Possible Dehydrated';
        utiRisk = 'Low';
      } else if (bestLabel == 'possible uti') {
        hydrationResult = 'Possible UTI';
        utiRisk = 'High';
      } else {
        hydrationResult = 'Normal';
        utiRisk = 'Low';
      }

      final historyRef = FirebaseFirestore.instance.collection('history');
      await historyRef.add({
        'userId': user.uid,
        'hydration': hydrationResult,
        'utiRisk': utiRisk,
        'imageUrl': imageUrl,
        'date': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              hydrationResult: hydrationResult,
              utiRisk: utiRisk,
              confidence: confidence,
              imageFile: _imageFile,
              detections: detections,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
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

            Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        _imageFile,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                      if (_isModelLoaded && !_isLoading)
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
                                  'Model Ready',
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
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is a preliminary screening tool only and does not replace medical diagnosis. Seek immediate medical attention for abnormal results.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: SizedBox(
                width: 220,
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
                      : const Icon(Icons.analytics_outlined, size: 24),
                  label: Text(
                    _isLoading
                        ? "Analyzing..."
                        : (_isModelLoaded
                              ? "Analyze Sample"
                              : "Loading Model..."),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (!_isLoading)
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    'Retake Photo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                ),
              ),

            const SizedBox(height: 24),
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
