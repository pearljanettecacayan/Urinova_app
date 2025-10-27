import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double normalIconSize = 35; // ✅ normal icons size
    final items = [
      Icons.home,
      Icons.list_alt,
      Icons.camera_alt_rounded, // ✅ QR icon (special)
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

          // ✅ Special QR icon (center, naka labaw gyud taas)
          if (index == 2) {
            return Expanded(
              child: GestureDetector(
                onTap: () => onItemTapped(index),
                child: Transform.translate(
                  offset: const Offset(0, -20), // gi-angat gyud
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromARGB(
                        255,
                        244,
                        246,
                        246,
                      ), // ✅ light white
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
                        size: 40, // ✅ QR mas dako
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

          // ✅ Normal icons with labels (always visible)
          return Expanded(
            child: GestureDetector(
              onTap: () => onItemTapped(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[index],
                    size: normalIconSize,
                    color: isSelected
                        ? Colors.teal
                        : const Color.fromARGB(255, 130, 189, 187),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLabel(index),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.teal
                          : const Color.fromARGB(255, 130, 189, 187),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
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
