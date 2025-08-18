import 'package:flutter/material.dart';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String selectedRoute = '';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.teal),
                ),
                SizedBox(height: 10),
                Text(
                  'Hello, User!',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('History'),
            selected: selectedRoute == '/history',
            selectedTileColor: Colors.teal.withOpacity(0.2),
            onTap: () {
              setState(() {
                selectedRoute = '/history';
              });
              Navigator.pushNamed(context, '/history');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            selected: selectedRoute == '/settings',
            selectedTileColor: Colors.teal.withOpacity(0.2),
            onTap: () {
              setState(() {
                selectedRoute = '/settings';
              });
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Log Out'),
            selected: selectedRoute == '/logout',
            selectedTileColor: Colors.teal.withOpacity(0.2),
            onTap: () {
              setState(() {
                selectedRoute = '/logout';
              });
              Navigator.pop(context); // close drawer
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
