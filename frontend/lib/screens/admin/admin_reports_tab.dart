// lib/screens/admin/admin_reports_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart'; // Your ApiService

// Model for Admin Report View
class AdminReportItem {
  final String fileName;
  final String? healthRiskPrediction;
  final String downloadLink;
  final DateTime uploadedAt;
  final String fileType;

  AdminReportItem({
    required this.fileName,
    this.healthRiskPrediction,
    required this.downloadLink,
    required this.uploadedAt,
    required this.fileType,
  });

  factory AdminReportItem.fromJson(Map<String, dynamic> json) {
    return AdminReportItem(
      fileName: json['fileName'] ?? 'N/A',
      healthRiskPrediction: json['healthRiskPrediction'],
      downloadLink: json['downloadLink'] ?? '',
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
      fileType: json['fileType'] ?? 'unknown',
    );
  }
}

class AdminReportsListingTab extends StatefulWidget {
  const AdminReportsListingTab({super.key});

  @override
  State<AdminReportsListingTab> createState() => _AdminReportsListingTabState();
}

class _AdminReportsListingTabState extends State<AdminReportsListingTab> {
  List<AdminReportItem> _reports = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _token;


  @override
  void initState() {
    super.initState();
    _initializeAndFetchReports();
  }

  Future<void> _initializeAndFetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (_token == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final List<dynamic> responseData = await ApiService.getAdminAllReports(_token!);
      if (mounted) {
        setState(() {
          _reports = responseData.map((data) => AdminReportItem.fromJson(data)).toList();
          _reports.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt)); // Sort newest first
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load reports: $e';
        });
      }
    }
  }

  Future<void> _downloadReport(String downloadPath) async {
    if (downloadPath.isEmpty) {
      Fluttertoast.showToast(msg: 'No download link available.');
      return;
    }
    // Assuming downloadLink is relative, e.g., /uploads/report.pdf
    // Prepend baseUrl if not already absolute
    final String fullUrl = downloadPath.startsWith('http')
        ? downloadPath
        : '${ApiService.baseUrl.replaceAll("/api", "")}$downloadPath'; // Adjust base URL if needed

    try {
      final Uri url = Uri.parse(fullUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error downloading report: $e', backgroundColor: Colors.red);
    }
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Uploaded Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : _reports.isEmpty
          ? const Center(child: Text('No reports found.'))
          : ListView.builder(
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Icon(
                report.fileType.contains('pdf') ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
              title: Text(report.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "Uploaded: ${_formatDateTime(report.uploadedAt)}\nRisk: ${report.healthRiskPrediction ?? 'N/A'}"
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.download_outlined, color: Colors.blue),
                tooltip: 'Download Report',
                onPressed: () => _downloadReport(report.downloadLink),
              ),
            ),
          );
        },
      ),
    );
  }
}