import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/CustomBottomNavBar.dart';
import 'recommendation.dart';

class ResultsScreen extends StatefulWidget {
  final String hydrationResult;
  final String utiRisk;
  final String confidence;

  const ResultsScreen({
    super.key,
    required this.hydrationResult,
    required this.utiRisk,
    required this.confidence,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _addNotification();
  }

  /// Add notification for results
  Future<void> _addNotification() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': 'New Analysis Result',
        'message':
            'Your latest analysis results are available. UTI Risk: ${widget.utiRisk}, Hydration: ${widget.hydrationResult}',
        'createdAt': Timestamp.now(),
        'read': false,
      });
    } catch (e) {
      print("Error adding notification: $e");
    }
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
        break;
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
          'Analysis Results',
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
              'Your Results:',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 20),
            _buildResultCard(
              'Analysis Result',
              widget.hydrationResult,
              '',
              Icons.water_drop,
              Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildResultCard(
              'UTI Risk',
              widget.utiRisk,
              widget.confidence,
              MdiIcons.alertCircleOutline,
              Colors.green,
            ),
            const SizedBox(height: 16),
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
                      'This application serves as a screening tool only and is not intended for diagnostic purposes. Consult a professional for clinical decisions.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecommendationScreen(
                      utiRisk: widget.utiRisk,
                      hydrationResult: widget.hydrationResult,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'See Recommendations',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
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

  Widget _buildResultCard(
    String title,
    String status,
    String confidence,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                if (confidence.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Confidence: $confidence%",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
