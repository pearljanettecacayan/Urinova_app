import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// ✅ Stream user data from Firestore
  Stream<Map<String, dynamic>?> _userDataStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          StreamBuilder<Map<String, dynamic>?>(
            stream: _userDataStream(),
            builder: (context, snapshot) {
              String displayName = "Hello, User!";
              String? photoUrl;

              if (snapshot.hasData && snapshot.data != null) {
                final userData = snapshot.data!;
                displayName = userData['name'] ?? "Hello, User!";
                photoUrl = userData['photoUrl'];
              }

              return DrawerHeader(
                decoration: const BoxDecoration(color: Colors.teal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.teal,
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              Navigator.pop(context); // close drawer

              // ✅ Sign out from Firebase
              await FirebaseAuth.instance.signOut();

              // ✅ Navigate to login screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
