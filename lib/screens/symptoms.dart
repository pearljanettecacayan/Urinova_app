import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/app_drawer.dart';
import '../components/CustomBottomNavBar.dart';

class SymptomsScreen extends StatefulWidget {
  @override
  _SymptomsScreenState createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  int _selectedIndex = 2;
  final List<String> _symptoms = [
    "Burning sensation during urination",
    "Frequent urge to urinate",
    "Cloudy urine",
    "Strong-smelling urine",
    "Lower abdominal pain",
    "Fever or chills"
  ];

  final Map<String, bool> _selectedSymptoms = {};

  @override
  void initState() {
    super.initState();
    for (var symptom in _symptoms) {
      _selectedSymptoms[symptom] = false;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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

  void _analyzeSymptoms() {
    final selected = _selectedSymptoms.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // For now, just show them in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Selected Symptoms"),
        content: Text(selected.isEmpty
            ? "No symptoms selected."
            : selected.join("\n")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Symptoms',
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
            // Placeholder for image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal),
              ),
              child: Icon(Icons.image, size: 80, color: Colors.teal),
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
                onChanged: (val) {
                  setState(() {
                    _selectedSymptoms[symptom] = val ?? false;
                  });
                },
                title: Text(symptom, style: GoogleFonts.poppins()),
                activeColor: Colors.teal,
              );
            }).toList(),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _analyzeSymptoms,
                icon: Icon(Icons.analytics),
                label: Text("Analyze"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
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
