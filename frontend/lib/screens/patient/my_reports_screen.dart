import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/bottom_nav_bar.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<dynamic> reports = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    loadTokenAndFetchReports();
  }

  Future<void> loadTokenAndFetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token != null) {
      await fetchReports();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.252.250:8080/api/patient/my-reports'), // change if deployed
        headers: {
          'Authorization': 'Bearer $token',

        },


      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          reports = data;
          isLoading = false;
        });
      } else {
        print('Failed to fetch reports: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
    print('Sending token: $token');


  }

  Widget buildReportTile(Map<String, dynamic> report) {
    final fileName = report['fileName'] ?? 'Unnamed';
    final uploadedAt = report['uploadedAt']?.substring(0, 10) ?? 'Unknown';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.folder_copy_rounded, color: Colors.deepPurple, size: 32),
        title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Uploaded on $uploadedAt'),
        trailing: IconButton(
          icon: const Icon(Icons.download_for_offline_rounded, color: Colors.green),
          onPressed: () {
            // Placeholder: Implement download logic if API gives file URL
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download not implemented for: $fileName')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📁 My Reports'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? const Center(child: Text('No reports found.', style: TextStyle(fontSize: 16)))
          : RefreshIndicator(
        onRefresh: fetchReports,
        child: ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) => buildReportTile(reports[index]),
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 3),
    );
  }
}
