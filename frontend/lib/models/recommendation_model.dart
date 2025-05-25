import 'package:flutter/material.dart';

class Recommendation {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? ctaText; // Call to action text e.g., "Learn More"
  final VoidCallback? onTap; // Action to perform on tap

  Recommendation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.ctaText,
    this.onTap,
  });

  // Factory constructor for creating a new Recommendation instance from a map
  // Placeholder for API integration
  factory Recommendation.fromJson(Map<String, dynamic> json, {VoidCallback? onTapCallback}) {
    return Recommendation(
      id: json['id'] ?? UniqueKey().toString(),
      title: json['title'] ?? 'Recommendation Title',
      subtitle: json['subtitle'] ?? 'Tap to learn more.',
      icon: _mapIcon(json['iconName'] ?? 'lightbulb'), // Re-use or create specific mapping
      color: _mapColor(json['colorName'] ?? 'blue').withOpacity(0.3),
      ctaText: json['ctaText'],
      onTap: onTapCallback, // You might pass navigation logic here
    );
  }
}