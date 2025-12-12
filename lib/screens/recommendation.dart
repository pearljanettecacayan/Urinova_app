import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  int _selectedIndex = 2;
  List<String> tips = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final firestore = FirebaseFirestore.instance;
      List<String> loadedTips = [];

      // Fetch UTI risk recommendations
      final utiRiskLower = widget.utiRisk.toLowerCase();
      final utiDoc = await firestore
          .collection('recommendations')
          .doc('uti_risks')
          .get();

      if (utiDoc.exists) {
        final data = utiDoc.data();
        if (data != null && data.containsKey(utiRiskLower)) {
          final riskData = data[utiRiskLower];
          if (riskData is String) {
            loadedTips.addAll(
              riskData
                  .split(',')
                  .map((tip) => tip.trim())
                  .where((tip) => tip.isNotEmpty),
            );
          } else if (riskData is List) {
            loadedTips.addAll(riskData.cast<String>());
          }
        }
      }

      // Fetch hydration recommendations
      final hydrationLower = widget.hydrationResult.toLowerCase();
      final hydrationDoc = await firestore
          .collection('recommendations')
          .doc('hydration')
          .get();

      if (hydrationDoc.exists) {
        final data = hydrationDoc.data();
        if (data != null && data.containsKey(hydrationLower)) {
          final hydrationData = data[hydrationLower];
          if (hydrationData is String) {
            loadedTips.addAll(
              hydrationData
                  .split(',')
                  .map((tip) => tip.trim())
                  .where((tip) => tip.isNotEmpty),
            );
          } else if (hydrationData is List) {
            loadedTips.addAll(hydrationData.cast<String>());
          }
        }
      }

      setState(() {
        tips = loadedTips;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load recommendations: $e';
        isLoading = false;
      });
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });
                        _loadRecommendations();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
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
                  if (tips.isEmpty)
                    Text(
                      'No recommendations available.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    ...tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 20,
                              color: Colors.teal,
                            ),
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
                          fontSize: 18,
                          color: Colors.white,
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
