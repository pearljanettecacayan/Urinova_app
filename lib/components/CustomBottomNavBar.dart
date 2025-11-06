import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasUnreadNotif =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        double normalIconSize = 35;
        final items = [
          Icons.home,
          Icons.list_alt,
          Icons.camera_alt_rounded,
          Icons.notifications,
          Icons.person,
        ];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = selectedIndex == index;

              // center camera icon
              if (index == 2) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onItemTapped(index),
                    child: Transform.translate(
                      offset: const Offset(0, -20),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(255, 244, 246, 246),
                          border: Border.all(color: Colors.teal, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            items[index],
                            size: 40,
                            color: isSelected
                                ? Colors.teal
                                : const Color.fromARGB(255, 130, 189, 187),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // normal icons (with badge)
              return Expanded(
                child: GestureDetector(
                  onTap: () => onItemTapped(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            items[index],
                            size: normalIconSize,
                            color: isSelected
                                ? Colors.teal
                                : const Color.fromARGB(255, 130, 189, 187),
                          ),
                          if (index == 3 && hasUnreadNotif)
                            const Positioned(
                              right: -2,
                              top: -2,
                              child: Icon(
                                Icons.circle,
                                color: Colors.red,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLabel(index),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.teal
                              : const Color.fromARGB(255, 130, 189, 187),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Instruction';
      case 2:
        return 'Capture';
      case 3:
        return 'Notification';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}
