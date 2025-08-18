import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndexScreen extends StatefulWidget {
  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late AnimationController _logoGrowController;
  late Animation<double> _logoGrowAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _showText = false;
  bool _hideText = false;

  @override
  void initState() {
    super.initState();

    // Initial bounce animation
    _logoController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Grow animation after text disappears
    _logoGrowController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _logoGrowAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _logoGrowController, curve: Curves.easeOutBack),
    );

    // Text fade and slide in
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start logo bounce
    _logoController.forward();

    // After logo bounce, show text
    Future.delayed(Duration(milliseconds: 1500), () {
      setState(() => _showText = true);
      _fadeController.forward();
      _slideController.forward();
    });

    // Hide text after 5 seconds, grow logo
    Future.delayed(Duration(milliseconds: 5000), () {
      setState(() => _hideText = true);
      _logoGrowController.forward(); // Grow logo
    });

    // Navigate after 5.7 seconds
    Future.delayed(Duration(milliseconds: 5700), () {
      Navigator.pushReplacementNamed(context, '/introduction');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _logoGrowController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _hideText ? _logoGrowAnimation : _logoAnimation,
                child: Icon(
                  Icons.health_and_safety,
                  size: 100,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 32),
              if (_showText && !_hideText)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Modified URINOVA with icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'URIN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                            Icon(
                              Icons.camera_alt,
                              size: 26,
                              color: Colors.teal[800],
                            ),
                            Text(
                              'VA',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Stay hydrated and healthy—check with Urinova.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceMono(
                            fontSize: 16,
                            color: Colors.grey[700],
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
