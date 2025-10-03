import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

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
import 'screens/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: "https://wbsnusrqruytavsrrnwc.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indic251c3JxcnV5dGF2c3JybndjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMDM4ODUsImV4cCI6MjA3MzU3OTg4NX0.D1YzwI3yvYYUEH0G9NKxTdbgx7XBax8bAKkD6oDdU38",
  );
  runApp(UrinalysisApp());
}

class UrinalysisApp extends StatefulWidget {
  @override
  State<UrinalysisApp> createState() => _UrinalysisAppState();
}

class _UrinalysisAppState extends State<UrinalysisApp> {
  bool _darkMode = false; // <-- dark mode state

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Urinalysis',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080),
          primary: const Color(0xFF008080),
          secondary: const Color(0xFF00C2A8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF008080),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          fillColor: Colors.white,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080),
          brightness: Brightness.dark,
        ),
      ),

      // ✅ Check kung naka-login ba ang user
      home: FirebaseAuth.instance.currentUser == null
          ? IndexScreen()
          : HomeScreen(),

      routes: {
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
        '/notifications': (context) => const NotificationsScreen(),
        '/settings': (context) =>
            SettingsScreen( // <-- pass dark mode toggle here
              darkMode: _darkMode,
              onDarkModeChanged: _toggleDarkMode,
            ),
        '/home': (context) => HomeScreen(),
        '/symptoms': (context) => SymptomsScreen(),
      },
    );
  }
}