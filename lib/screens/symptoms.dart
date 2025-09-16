import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/app_drawer.dart';
import '../components/CustomBottomNavBar.dart';

class SymptomsScreen extends StatefulWidget {
  final File? capturedImage; // optional: urine image gikan sa capture

  SymptomsScreen({this.capturedImage});

  @override
  _SymptomsScreenState createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  int _selectedIndex = 2;

  // Symptoms list
  final List<String> _symptoms = [
    "Pain or burning during urination",
    "Frequent urination",
    "Cloudy urine",
    "Strong-smelling urine",
    "Abdominal or pelvic pain",
    "Possible fever",
    "Thirst",
    "Dry mouth or lips",
    "Low urine output",
    "Dizziness or weakness",
  ];

  // Medications list
  final List<String> _medicationQuestions = [
    "Are you currently taking antibiotics?",
    "Are you taking pain relievers (e.g., paracetamol, ibuprofen)?",
    "Are you on any medication for urinary problems?",
    "Are you taking vitamins or supplements?",
    "Are you taking any herbal medicine for urinary symptoms?",
  ];

  // State maps
  final Map<String, bool> _selectedSymptoms = {};
  final Map<String, bool> _selectedMedications = {};

  @override
  void initState() {
    super.initState();
    for (var s in _symptoms) {
      _selectedSymptoms[s] = false;
    }
    for (var m in _medicationQuestions) {
      _selectedMedications[m] = false;
    }
  }

  void _analyzeSymptoms() {
    final selectedSymptoms = _selectedSymptoms.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final selectedMeds = _selectedMedications.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Selected Information"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Symptoms:",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(selectedSymptoms.isEmpty
                  ? "No symptoms selected."
                  : selectedSymptoms.join("\n")),
              const SizedBox(height: 12),
              Text("Medications:",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(selectedMeds.isEmpty
                  ? "No medications selected."
                  : selectedMeds.join("\n")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pushReplacementNamed(context, '/results');
            },
            child: const Text("Proceed"),
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
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
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
            // Captured Image
            Text(
              "Captured Urine Image",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal),
              ),
              child: widget.capturedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(widget.capturedImage!,
                          fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image,
                      size: 80, color: Colors.teal),
            ),
            const SizedBox(height: 24),

            // Symptoms choices
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
                value: _selectedSymptoms[symptom] ?? false,
                onChanged: (val) {
                  setState(() {
                    _selectedSymptoms[symptom] = val ?? false;
                  });
                },
                title: Text(symptom, style: GoogleFonts.poppins()),
                activeColor: Colors.teal,
              );
            }).toList(),
            const SizedBox(height: 24),

            // Medications choices
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
                value: _selectedMedications[question] ?? false,
                onChanged: (val) {
                  setState(() {
                    _selectedMedications[question] = val ?? false;
                  });
                },
                title: Text(question, style: GoogleFonts.poppins()),
                activeColor: Colors.teal,
              );
            }).toList(),
            const SizedBox(height: 24),

            // Analyze Button at the bottom
            Center(
              child: ElevatedButton.icon(
                onPressed: _analyzeSymptoms,
                icon: const Icon(Icons.analytics),
                label: const Text("Analyze"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80), // gap para dili matabunan sa navbar
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
