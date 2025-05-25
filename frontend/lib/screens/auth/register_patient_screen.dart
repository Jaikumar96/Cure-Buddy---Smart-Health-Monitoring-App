import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // Assuming this path is correct
import 'register_doctor_screen.dart';
// import 'login_screen.dart'; // Example: if you have a login screen to navigate to

class RegisterPatientScreen extends StatefulWidget {
  @override
  _RegisterPatientScreenState createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>(); // For Form validation
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController(); // For password confirmation

  bool _isLoading = false;
  String _apiMessage = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    // Dispose controllers to free up resources
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Check if form is valid
      setState(() {
        _isLoading = true;
        _apiMessage = ''; // Clear previous messages
        _isSuccess = false;
      });

      try {
        // In a real app, ApiService.registerPatient might return a more structured response
        // e.g., a custom object or a Map<String, dynamic> indicating success/failure and message.
        // For now, we'll assume it returns a success message string or throws an error.
        final responseMessage = await ApiService.registerPatient(
          nameController.text,
          emailController.text,
          passwordController.text,
        );

        setState(() {
          _apiMessage = responseMessage; // Or "Registration successful!"
          _isSuccess = true;
          // Optionally clear fields or navigate
          // nameController.clear();
          // emailController.clear();
          // passwordController.clear();
          // confirmPasswordController.clear();

          // Example: Navigate to login screen after a delay
          // Future.delayed(Duration(seconds: 2), () {
          //   if (mounted) {
          //     Navigator.of(context).pushReplacement(
          //       MaterialPageRoute(builder: (_) => LoginScreen()),
          //     );
          //   }
          // });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseMessage ?? 'Registration Successful!'),
            backgroundColor: Colors.green,
          ),
        );

      } catch (e) {
        // Handle specific API errors if ApiService throws them,
        // otherwise, show a generic error.
        setState(() {
          _apiMessage = "Registration failed: ${e.toString()}";
          _isSuccess = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_apiMessage),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) { // Check if the widget is still in the tree
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Signup"),
        //backgroundColor: Colors.deepPurple, // Example theming
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          // Wrap content in a Form widget
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons stretch
            children: [
              Image.asset(
                'assets/patient_register.gif', // Ensure this asset is in pubspec.yaml and path is correct
                height: 200, // Adjusted height
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person_add_alt_1, size: 150, color: Colors.grey); // Placeholder if image fails
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _handleRegister,
                  child: Text("SIGN UP"),
                  style: ElevatedButton.styleFrom(
                    //backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              SizedBox(height: 12),
              // This is where _apiMessage was, but SnackBar is often better
              // if (_apiMessage.isNotEmpty)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 10.0),
              //     child: Text(
              //       _apiMessage,
              //       style: TextStyle(
              //         color: _isSuccess ? Colors.green : Colors.red,
              //         fontWeight: FontWeight.bold,
              //       ),
              //       textAlign: TextAlign.center,
              //     ),
              //   ),
              SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterDoctorScreen()),
                  );
                },
                child: Text("Register as Doctor"),
                style: OutlinedButton.styleFrom(
                  //side: BorderSide(color: Colors.deepPurple),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}