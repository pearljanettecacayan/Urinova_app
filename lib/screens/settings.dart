import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal, // <--- TEAL COLOR
        iconTheme: const IconThemeData(color: Colors.white), // <-- WHITE BACK ARROW
        title: Text('Settings', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'General',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          SwitchListTile(
            title: Text('Enable Notifications', style: GoogleFonts.poppins()),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Dark Mode (Coming Soon)', style: GoogleFonts.poppins()),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Dark mode not available yet.")),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Language',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            items: ['English', 'Cebuano', 'Tagalog']
                .map((lang) => DropdownMenuItem(
                      value: lang,
                      child: Text(lang, style: GoogleFonts.poppins()),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}