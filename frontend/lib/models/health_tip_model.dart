import 'package:flutter/material.dart'; // For IconData

class HealthTip {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconBackgroundColor;

  HealthTip({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBackgroundColor,
  });

  // Factory constructor for creating a new HealthTip instance from a map (e.g., JSON from API)
  // This is a placeholder for when you connect to a real API
  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      id: json['id'] ?? UniqueKey().toString(),
      title: json['title'] ?? 'Default Tip Title',
      description: json['description'] ?? 'Default tip description.',
      // You'll need a way to map icon names from API to IconData or use image URLs
      icon: _mapIcon(json['iconName'] ?? 'spa'), // Example mapping
      iconBackgroundColor: _mapColor(json['iconColor'] ?? 'green'), // Example mapping
    );
  }
}

IconData _mapIcon(String iconName) {
  // Example: map icon names from API to Material Icons
  switch (iconName.toLowerCase()) {
    case 'water':
      return Icons.water_drop_outlined;
    case 'sleep':
      return Icons.nights_stay_outlined;
    case 'food':
      return Icons.restaurant_outlined;
    case 'mindfulness':
      return Icons.self_improvement_outlined;
    case 'fitness':
      return Icons.fitness_center_outlined;
    default:
      return Icons.spa_outlined; // Default icon
  }
}

Color _mapColor(String colorName) {
  switch (colorName.toLowerCase()) {
    case 'blue':
      return Colors.blue.shade100;
    case 'green':
      return Colors.green.shade100;
    case 'orange':
      return Colors.orange.shade100;
    case 'purple':
      return Colors.purple.shade100;
    default:
      return Colors.teal.shade100;
  }
}