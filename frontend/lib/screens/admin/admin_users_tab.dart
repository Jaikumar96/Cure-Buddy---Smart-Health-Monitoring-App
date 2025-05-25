// lib/screens/admin/admin_users_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

// Model for User (can be enhanced)
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? registrationNumber; // <<< ADDED: Specific to DOCTOR, nullable
  final bool? licenseVerified; // Specific to DOCTOR, nullable

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.registrationNumber, // <<< ADDED
    this.licenseVerified,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String, // It's good practice to assert type or handle potential nulls if API isn't strict
      name: json['name'] as String? ?? 'N/A',
      email: json['email'] as String? ?? 'N/A',
      role: json['role'] as String? ?? 'UNKNOWN',
      registrationNumber: json['registrationNumber'] as String?, // <<< ADDED
      licenseVerified: json['licenseVerified'] as bool?,
    );
  }
}

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _initializeAndFetchUsers();
  }

  Future<void> _initializeAndFetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (!mounted) return;
    if (_token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
      return;
    }
    _fetchUsers();
  }


  Future<void> _fetchUsers() async {
    if (_token == null) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final List<dynamic> responseData = await ApiService.getAdminAllUsers(_token!);
      if (mounted) {
        setState(() {
          _users = responseData.map((data) => AppUser.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load users: $e';
        });
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    if (_token == null) return;
    if (!mounted) return;

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await ApiService.deleteAdminUser(_token!, userId);
        Fluttertoast.showToast(msg: 'User deleted successfully.');
        _fetchUsers(); // Refresh the list
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to delete user: $e', backgroundColor: Colors.red);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : _users.isEmpty
          ? const Center(child: Text('No users found.'))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          // Decide what to show for subtitle based on user role or available info
          String subtitleText = '${user.email}\nRole: ${user.role}';
          if (user.role == 'DOCTOR') {
            subtitleText += '\nReg No: ${user.registrationNumber ?? "N/A"}';
            subtitleText += '\nVerified: ${user.licenseVerified == true ? "Yes" : "No"}';
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorLight,
                child: Text(user.role.isNotEmpty ? user.role.substring(0,1).toUpperCase() : 'U', style: TextStyle(color: Theme.of(context).primaryColorDark)),
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(subtitleText),
              isThreeLine: user.role == 'DOCTOR', // Make it three-line for doctors to show more info
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete User',
                onPressed: () => _deleteUser(user.id),
              ),
            ),
          );
        },
      ),
    );
  }
}