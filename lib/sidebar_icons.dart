import 'package:flutter/material.dart';

class SidebarIcons extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const SidebarIcons({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: const Color(0xFF385B4F),
      child: Column(
        children: [
          const SizedBox(height: 40),
          buildIcon(Icons.home, 0), // Top home icon

          const Spacer(), // Space before middle icons

          // Middle icons
          buildIcon(Icons.bar_chart, 1),
          const SizedBox(height: 30),
          buildIcon(Icons.event, 2),
          const SizedBox(height: 30),
          buildIcon(Icons.camera_alt, 3),

          const Spacer(), // Space after middle icons

          // Bottom icon
          buildIcon(Icons.settings, 4),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildIcon(IconData icon, int index) {
    return GestureDetector(
      onTap: () => onSelect(index),
      child: Icon(
        icon,
        size: 30,
        color: selectedIndex == index ? Colors.grey : Colors.grey,
      ),
    );
  }
}