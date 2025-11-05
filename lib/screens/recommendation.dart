import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/CustomBottomNavBar.dart';

class RecommendationScreen extends StatefulWidget {
  final String utiRisk;
  final String hydrationResult;

  const RecommendationScreen({
    super.key,
    required this.utiRisk,
    required this.hydrationResult,
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  int _selectedIndex = 2; // Index 2 = Capture
  late List<String> tips;

  @override
  void initState() {
    super.initState();

    tips = [];

    // UTI Risk-based tips
    if (widget.utiRisk.toLowerCase() == 'high') {
      tips.addAll([
        'See a doctor as soon as possible.',
        'Urinate frequently and don’t hold it in.',
        'Maintain good hygiene after using the toilet.',
      ]);
    } else if (widget.utiRisk.toLowerCase() == 'medium') {
      tips.addAll([
        'Monitor your symptoms closely.',
        'Avoid sugary drinks.',
        'Consult a doctor if symptoms worsen.',
      ]);
    } else {
      tips.addAll([
        'Maintain proper hygiene.',
        'Stay aware of your symptoms.',
      ]);
    }

    // Hydration-based tips
    if (widget.hydrationResult.toLowerCase() == 'low') {
      tips.addAll([
        'Increase your water intake to stay hydrated.',
        'Avoid caffeine and alcohol.',
      ]);
    } else if (widget.hydrationResult.toLowerCase() == 'moderate') {
      tips.add('Maintain your current water intake.');
    } else if (widget.hydrationResult.toLowerCase() == 'high') {
      tips.add('Keep up your good hydration habits.');
    }
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
        break; // Already on this screen
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Recommendations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Health Tips:',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 16),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 20, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                      fontSize: 18, color: Colors.white),
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
