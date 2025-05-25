// lib/screens/admin/admin_doctors_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import 'admin_users_tab.dart'; // For AppUser model

class AdminDoctorsTab extends StatefulWidget {
  const AdminDoctorsTab({super.key});

  @override
  State<AdminDoctorsTab> createState() => _AdminDoctorsTabState();
}

class _AdminDoctorsTabState extends State<AdminDoctorsTab> {
  List<AppUser> _doctors = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _token;


  @override
  void initState() {
    super.initState();
    _initializeAndFetchDoctors();
  }

  Future<void> _initializeAndFetchDoctors() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (!mounted) return; // Check if widget is still in the tree
    if (_token == null) {
      // It's generally better to avoid calling Navigator methods directly in initState
      // or build methods without careful consideration of the widget lifecycle.
      // However, if this is a hard requirement, ensure it's guarded.
      // A common pattern is to navigate after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Check mounted again inside postFrameCallback
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
      return;
    }
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    if (_token == null) return;
    if (!mounted) return; // Guard against calling setState on unmounted widget
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final List<dynamic> responseData = await ApiService.getAdminAllUsers(_token!);
      if (mounted) {
        setState(() {
          _doctors = responseData
              .map((data) => AppUser.fromJson(data))
              .where((user) => user.role == 'DOCTOR')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load doctors: $e';
        });
      }
    }
  }

  Future<void> _verifyDoctor(String doctorEmail) async {
    if (_token == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true); // Indicate loading for verification
    try {
      await ApiService.verifyDoctorLicense(_token!, doctorEmail);
      Fluttertoast.showToast(msg: 'Doctor $doctorEmail verified successfully.');
      _fetchDoctors(); // Refresh the list to show updated status
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to verify doctor: $e', backgroundColor: Colors.red);
      if (mounted) {
        // Only set isLoading to false if _fetchDoctors is not called or if it completes immediately
        // Since _fetchDoctors sets _isLoading, this might be redundant or handled by _fetchDoctors
        // For simplicity, _fetchDoctors will handle setting _isLoading back to false on completion/error.
        // However, if verification fails, we might want to set _isLoading = false here directly.
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDoctors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : _doctors.isEmpty
          ? const Center(child: Text('No doctors found or to verify.'))
          : ListView.builder(
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Icon(
                doctor.licenseVerified == true // Assuming licenseVerified is bool, can be simplified if non-nullable
                    ? Icons.verified_user
                    : Icons.gpp_maybe_outlined,
                color: doctor.licenseVerified == true ? Colors.green : Colors.orange,
                size: 30,
              ),
              title: Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "${doctor.email}\n"
                      "Registration Number: ${doctor.registrationNumber ?? 'N/A'}\n" // Added Registration Number
                      "License Verified: ${doctor.licenseVerified == true ? 'Yes' : 'No'}"
              ),
              isThreeLine: true, // Ensure this is true to accommodate the three lines of text
              trailing: doctor.licenseVerified == true
                  ? null // Already verified
                  : ElevatedButton(
                onPressed: () => _verifyDoctor(doctor.email),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  // foregroundColor: Colors.white, // Optional: for text color if needed
                ),
                child: const Text('Verify'),
              ),
            ),
          );
        },
      ),
    );
  }
}