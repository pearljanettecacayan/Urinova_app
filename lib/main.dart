import 'package:flutter/material.dart';
import 'screens/index.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/introduction.dart';
import 'screens/instructions.dart';
import 'screens/capture.dart';
import 'screens/results.dart';
import 'screens/recommendation.dart';
import 'screens/profile.dart';
import 'screens/editprofile.dart';
import 'screens/history.dart';
import 'screens/settings.dart';
import 'screens/home.dart';
import 'screens/symptoms.dart';

void main() {
  runApp(UrinalysisApp());
}

class UrinalysisApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Urinalysis',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Color(0xFFF9F9F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF008080),
          primary: Color(0xFF008080),
          secondary: Color(0xFF00C2A8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF008080),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          fillColor: Colors.white,
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>IndexScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/introduction': (context) => IntroductionScreen(),
        '/instructions': (context) => InstructionsScreen(),
        '/capture': (context) => CaptureScreen(),
        '/results': (context) => ResultsScreen(),
        '/recommendation': (context) => RecommendationScreen(),
        '/profile': (context) => ProfileScreen(),
        '/editProfile': (context) => EditProfileScreen(),
        '/history': (context) => HistoryScreen(),
        '/settings': (context) => SettingsScreen(),
        '/home': (context) => HomeScreen(),
        '/symptoms': (context) => SymptomsScreen(),
      },
    );
  }
}
