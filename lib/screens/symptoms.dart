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

  final List<String> _symptoms = [
    "Burning sensation during urination",
    "Frequent urge to urinate",
    "Cloudy urine",
    "Strong-smelling urine",
    "Lower abdominal pain",
    "Fever or chills",
    "None",
  ];

  final List<String> _medicationQuestions = [
    "Are you currently taking antibiotics?",
    "Are you taking pain relievers (e.g., paracetamol, ibuprofen)?",
    "Are you on any medication for urinary problems?",
    "Are you taking vitamins or supplements?",
    "Are you taking any herbal medicine for urinary symptoms?",
    "None",
  ];

  final Map<String, bool> _selectedSymptoms = {};
  final Map<String, bool> _selectedMedications = {};

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;

    for (var s in _symptoms) _selectedSymptoms[s] = false;
    for (var m in _medicationQuestions) _selectedMedications[m] = false;

    _loadModelInBackground();
  }

  void _loadModelInBackground() async {
    await _tfliteHelper.loadModel();
    if (_tfliteHelper.isLoaded) {
      if (mounted) setState(() => _isModelLoaded = true);
    }
  }

  Future<void> _analyzeSymptoms() async {
    if (!_isModelLoaded) return;

    setState(() => _isLoading = true);

    if (!await _imageFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image file not found!')),
      );
      setState(() => _isLoading = false);
      return;
    }

    List<double> results = [];
    try {
      results = await _tfliteHelper.runModel(_imageFile);
      if (results.isEmpty) throw Exception("Inference returned empty results");
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error during inference: $e')));
      setState(() => _isLoading = false);
      return;
    }

    final labels = ['Possible Dehydrated', 'Normal', 'Possible UTI'];
    final bestIndex = results.indexOf(results.reduce((a, b) => a > b ? a : b));
    final bestLabel = labels[bestIndex];
    final confidence = (results[bestIndex] * 100).toStringAsFixed(2);

    final selectedSymptoms = _selectedSymptoms.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final selectedMeds = _selectedMedications.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // Upload image to Supabase
    late String imageUrl;
    final fileName = 'urine_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bucketName = 'urine_images';
    try {
      await supabase.storage.from(bucketName).upload(fileName, _imageFile);
      imageUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Supabase upload failed: $e')));
      setState(() => _isLoading = false);
      return;
    }

    // Save to Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please log in first.')));
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('analysis_results').add({
        'userId': user.uid,
        'timestamp': DateTime.now(),
        'result': bestLabel,
        'confidence': confidence,
        'symptoms': selectedSymptoms,
        'medications': selectedMeds,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Firestore save failed: $e')));
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          hydrationResult: bestLabel == 'Normal' ? 'Normal' : bestLabel,
          utiRisk: bestLabel == 'Possible UTI' ? 'High' : 'Low',
          confidence: confidence,
          symptoms: selectedSymptoms,
          medications: selectedMeds,
        ),
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
          'Symptoms & Medications',
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
              child: Image.file(
                _imageFile,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Select Symptoms You Are Experiencing:",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),
            ..._symptoms.map((symptom) {
              return CheckboxListTile(
                value: _selectedSymptoms[symptom],
                onChanged: (val) =>
                    setState(() => _selectedSymptoms[symptom] = val ?? false),
                title: Text(symptom, style: GoogleFonts.poppins()),
                activeColor: Colors.teal,
              );
            }).toList(),
            const SizedBox(height: 24),
            Text(
              "Medication Intake Questions:",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),
            ..._medicationQuestions.map((question) {
              return CheckboxListTile(
                value: _selectedMedications[question],
                onChanged: (val) => setState(
                  () => _selectedMedications[question] = val ?? false,
                ),
                title: Text(question, style: GoogleFonts.poppins()),
                activeColor: Colors.teal,
              );
            }).toList(),
            const SizedBox(height: 24),
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
                    _isModelLoaded ? "Analyze" : "Loading Model...",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
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
