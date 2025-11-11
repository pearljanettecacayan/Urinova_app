import 'package:flutter/material.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late AnimationController _logoGrowController;
  late Animation<double> _logoGrowAnimation;

  @override
  void initState() {
    super.initState();

    // Initial bounce animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Grow animation after bounce
    _logoGrowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _logoGrowAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _logoGrowController, curve: Curves.easeOutBack),
    );

    // Start logo bounce
    _logoController.forward();

    // After 1.5s, play grow
    Future.delayed(const Duration(milliseconds: 2000), () {
      _logoGrowController.forward();
    });

    // Navigate after 2.5s
    Future.delayed(const Duration(milliseconds: 3500), () {
      Navigator.pushReplacementNamed(context, '/introduction');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _logoGrowController.dispose();
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
          child: ScaleTransition(
            scale: _logoGrowController.isAnimating
                ? _logoGrowAnimation
                : _logoAnimation,
            child: const Icon(
              Icons.health_and_safety,
              size: 100,
              color: Colors.teal,
            ),
          ),
        ),
      ),
    );
  }
}
