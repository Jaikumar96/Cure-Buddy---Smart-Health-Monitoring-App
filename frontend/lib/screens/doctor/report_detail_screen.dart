// lib/screens/doctor/report_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart'; // Your ApiService
import 'doctor_reports_tab.dart'; // For PatientReport model

class ReportDetailScreen extends StatefulWidget {
  final PatientReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _remarksController = TextEditingController();
  final _adviceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.report.doctorRemarks ?? '';
    _adviceController.text = widget.report.doctorAdvice ?? '';
  }

  Future<void> _submitResponse() async {
    if (_remarksController.text.isEmpty || _adviceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both remarks and advice.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Ensure widget.report.id is not null.
      // The API uses reportId in the path. In your patient_reports list,
      // each item might not have a distinct 'id' field.
      // You'll need to make sure the `PatientReport` model gets a unique ID from the backend data.
      // If your `/api/doctor/patient-reports` response items don't have a unique ID,
      // you'll need to adjust the backend or find another unique identifier to use.
      // For now, I'm assuming `widget.report.id` will be the correct ID for the report document.
      // The API spec POST /api/doctor/respond/{reportId} - reportId is likely the MongoDB ObjectId
      // of the HealthReport document.

      String reportDocumentId = widget.report.id ?? "";
      print("--- Submitting Doctor Response ---");
      print("Using Report Document ID for API call: $reportDocumentId"); // <--- ADD THIS LOG
      print("Remarks: ${_remarksController.text}");
      print("Advice: ${_adviceController.text}");


      if (reportDocumentId.isEmpty || reportDocumentId == widget.report.fileName) { // Add check if it defaulted to fileName
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Critical - Report Document ID is missing or invalid. Cannot submit.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await ApiService.addDoctorResponse(
        token,
        reportDocumentId,
        _remarksController.text,
        _adviceController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response submitted successfully!')),
        );
        Navigator.pop(context, true); // Pop and signal to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit response: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _adviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${widget.report.fileName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Patient Email:', widget.report.patientEmail),
            _buildDetailItem('File Name:', widget.report.fileName),
            _buildDetailItem('Health Risk:', widget.report.healthRiskPrediction ?? 'N/A',
              valueColor: widget.report.healthRiskPrediction == "CRITICAL" ? Colors.red
                  : widget.report.healthRiskPrediction == "MODERATE" ? Colors.orange
                  : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              'Doctor\'s Response',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 10),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _adviceController,
              decoration: const InputDecoration(
                labelText: 'Advice',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Submit Response'),
              onPressed: _submitResponse,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}