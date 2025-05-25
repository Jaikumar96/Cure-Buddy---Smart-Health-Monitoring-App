// lib/screens/doctor/doctor_search_patient_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../../services/api_service.dart'; // Not directly used here for search, but PatientHistoryScreen uses it
import 'patient_history_screen.dart';

class DoctorSearchPatientTab extends StatefulWidget {
  const DoctorSearchPatientTab({super.key});

  @override
  State<DoctorSearchPatientTab> createState() => _DoctorSearchPatientTabState();
}

class _DoctorSearchPatientTabState extends State<DoctorSearchPatientTab> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For validation
  bool _isSearching = false; // Still useful for disabling button

  Future<void> _searchPatient() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _searchController.text.trim();
    setState(() => _isSearching = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        setState(() => _isSearching = false);
        return;
      }

      // Navigate to PatientHistoryScreen, which will handle its own loading and errors.
      // Errors from _searchPatient itself are less likely now, more about token validity.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientHistoryScreen(patientEmail: email, token: token),
        ),
      ).then((_) {
        // Reset search state when returning from history screen
        if (mounted) {
          setState(() => _isSearching = false);
        }
      });

    } catch (e) {
      // This catch is unlikely to be hit if the main logic is navigation.
      // Errors will more likely be handled within PatientHistoryScreen or by token check.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
        setState(() => _isSearching = false);
      }
    }
    // No finally block needed to set _isSearching = false here,
    // as it's reset in .then() after navigation or if token is null.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Patient History'),
      ),
      body: GestureDetector( // Dismiss keyboard on tap outside
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1), // Push content down a bit
                Icon(
                  Icons.person_search_sharp,
                  size: 100,
                  color: theme.colorScheme.primary.withOpacity(0.8),
                ),
                const SizedBox(height: 20),
                Text(
                  'Find Patient Records',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the patient\'s email address below to retrieve their medical report history.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Patient Email',
                    hintText: 'e.g., patient@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: theme.hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a patient email.';
                    }
                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!_isSearching) _searchPatient();
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: _isSearching
                      ? Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                      strokeWidth: 3,
                    ),
                  )
                      : const Icon(Icons.search_rounded),
                  label: Text(_isSearching ? 'SEARCHING...' : 'Search History'),
                  onPressed: _isSearching ? null : _searchPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1), // Some bottom space
              ],
            ),
          ),
        ),
      ),
    );
  }
}