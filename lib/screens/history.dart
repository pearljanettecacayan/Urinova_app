import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  final List<Map<String, String>> historyItems = [
    {
      'date': 'July 25, 2025',
      'hydration': 'Normal',
      'utiRisk': 'Low',
    },
    {
      'date': 'July 18, 2025',
      'hydration': 'Dehydrated',
      'utiRisk': 'Moderate',
    },
    {
      'date': 'July 10, 2025',
      'hydration': 'Normal',
      'utiRisk': 'Low',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         backgroundColor: Colors.teal, // <--- TEAL COLOR
         iconTheme: const IconThemeData(color: Colors.white), // <-- WHITE BACK ARROW
        title: Text('History', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: historyItems.isEmpty
            ? Center(
                child: Text(
                  'No history found.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8,),
                    child: ListTile(
                      leading: Icon(Icons.history, color: Colors.teal),
                      title: Text(
                        item['date']!,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Hydration: ${item['hydration']} • UTI Risk: ${item['utiRisk']}',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}