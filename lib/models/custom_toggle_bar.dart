import 'package:flutter/material.dart';

class CustomToggleBar extends StatelessWidget {
  final bool isSelected;
  final Function(bool) onToggle;

  CustomToggleBar({required this.isSelected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20), // ✅ Adds left & right spacing
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => onToggle(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.red : Colors.grey[300],
                foregroundColor: isSelected ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              child: Text('Log Meal'),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onToggle(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: !isSelected ? Colors.red : Colors.grey[300],
                foregroundColor: !isSelected ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
              child: Text('Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}
