import 'package:flutter/material.dart';

class HealthAnalysisWidget extends StatelessWidget {
  final String riskLevel;
  final String trend;
  final String details;
  final List<String> tips;

  const HealthAnalysisWidget({
    Key? key,
    required this.riskLevel,
    required this.trend,
    required this.details,
    required this.tips,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple[50],
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Risk: $riskLevel',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Trend: $trend',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Details: $details',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Health Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...tips.map((tip) => Text('- $tip')).toList(),
          ],
        ),
      ),
    );
  }
  }
