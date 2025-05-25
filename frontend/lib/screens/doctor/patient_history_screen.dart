// lib/screens/doctor/patient_history_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'doctor_reports_tab.dart'; // For PatientReport model
import 'report_detail_screen.dart'; // To view/respond to a specific report from history


// Model for Patient History Item (includes uploadedAt)
class PatientHistoryItem {
  final String? id;
  final String fileName;
  final String? healthRiskPrediction;
  final String? doctorRemarks;
  final String? doctorAdvice;
  final DateTime uploadedAt;

  PatientHistoryItem({
    this.id,
    required this.fileName,
    this.healthRiskPrediction,
    this.doctorRemarks,
    this.doctorAdvice,
    required this.uploadedAt,
  });

  factory PatientHistoryItem.fromJson(Map<String, dynamic> json) {
    return PatientHistoryItem(
      id: json['id'] ?? json['reportId'] ?? json['fileName'], // Ensure you get a unique ID
      fileName: json['fileName'],
      healthRiskPrediction: json['healthRiskPrediction'],
      doctorRemarks: json['doctorRemarks'],
      doctorAdvice: json['doctorAdvice'],
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PatientHistoryScreen extends StatefulWidget {
  final String patientEmail;
  final String token; // Pass token for API calls

  const PatientHistoryScreen({
    super.key,
    required this.patientEmail,
    required this.token,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  List<PatientHistoryItem> _history = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPatientHistory();
  }

  Future<void> _fetchPatientHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final List<dynamic> responseData =
      await ApiService.getPatientHistory(widget.token, widget.patientEmail);
      if (mounted) {
        setState(() {
          _history = responseData.map((data) => PatientHistoryItem.fromJson(data)).toList();
          // Sort by date, newest first
          _history.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load patient history: $e';
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History: ${widget.patientEmail}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : _history.isEmpty
          ? Center(
          child: Text(
            'No history found for this patient.',
            style: Theme.of(context).textTheme.titleMedium,
          ))
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          // We need to map PatientHistoryItem to PatientReport if navigating to ReportDetailScreen
          final reportForDetail = PatientReport(
            id: item.id,
            fileName: item.fileName,
            healthRiskPrediction: item.healthRiskPrediction,
            doctorRemarks: item.doctorRemarks,
            doctorAdvice: item.doctorAdvice,
            patientEmail: widget.patientEmail, // Add patient email to PatientReport if needed by detail screen
          );
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                item.healthRiskPrediction == "CRITICAL" ? Icons.warning_amber_rounded
                    : item.healthRiskPrediction == "MODERATE" ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: item.healthRiskPrediction == "CRITICAL" ? Colors.red
                    : item.healthRiskPrediction == "MODERATE" ? Colors.orange
                    : Colors.green,
              ),
              title: Text(item.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "Uploaded: ${_formatDate(item.uploadedAt)}\nRisk: ${item.healthRiskPrediction ?? 'N/A'}\nStatus: ${item.doctorRemarks == null ? 'Pending Review' : 'Reviewed'}"
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Pass the full report object
                    builder: (context) => ReportDetailScreen(report: reportForDetail),
                  ),
                ).then((value) {
                  if (value == true) { // If response submitted
                    _fetchPatientHistory(); // Refresh history
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }
}