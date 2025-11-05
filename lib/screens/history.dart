import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('History', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: user == null
          ? Center(
              child: Text('Please log in to view your history.',
                  style: GoogleFonts.poppins(fontSize: 16)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('history')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading history.',
                        style: GoogleFonts.poppins(fontSize: 16)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text('No history found.',
                        style: GoogleFonts.poppins(fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final hydration = data['hydration'] ?? 'Unknown';
                    final utiRisk = data['utiRisk'] ?? 'Unknown';
                    final timestamp = data['date'] as Timestamp?;
                    final date = timestamp != null
                        ? timestamp.toDate()
                        : DateTime.now();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading:
                            const Icon(Icons.history, color: Colors.teal),
                        title: Text(
                          '${date.month}/${date.day}/${date.year}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Hydration: $hydration • UTI Risk: $utiRisk',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
