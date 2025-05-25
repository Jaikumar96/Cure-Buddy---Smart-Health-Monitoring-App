import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // Assuming this path is correct

class RegisterDoctorScreen extends StatefulWidget {
  @override
  _RegisterDoctorScreenState createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regNumberController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _regNumberFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _message = '';
  bool _isSuccessMessage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regNumberController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _regNumberFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus(); // Hide keyboard

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      try {
        final response = await ApiService.registerDoctor(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _regNumberController.text.trim(),
        );
        if (mounted) {
          setState(() {
            _message = response ?? "Registration successful! Please wait for admin verification.";
            _isSuccessMessage = true;
            // Optionally clear fields on success
            // _formKey.currentState?.reset();
            // _nameController.clear();
            // _emailController.clear();
            // _passwordController.clear();
            // _regNumberController.clear();

            // You might want to navigate away or show a success dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_message),
                backgroundColor: Colors.green,
              ),
            );
            // Potentially navigate back or to a "pending verification" screen
            // Navigator.of(context).pop();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _message = "Registration failed: ${e.toString().replaceFirst("Exception: ", "")}";
            _isSuccessMessage = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_message),
                backgroundColor: Colors.red,
              ),
            );
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() {
        _message = "Please correct the errors above.";
        _isSuccessMessage = false;
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateRegNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your registration number';
    }
    // Add more specific validation for reg number if needed
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Signup"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/doctor_register.gif', // Ensure this asset exists
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.medical_services_outlined, size: 150, color: theme.colorScheme.primary.withOpacity(0.7));
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  "Create Doctor Account",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocusNode),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_regNumberFocusNode),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _regNumberController,
                  focusNode: _regNumberFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Medical Registration Number',
                    prefixIcon: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: _validateRegNumber,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _handleRegister(),
                ),
                const SizedBox(height: 24),
                // if (_message.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.only(bottom: 16.0),
                //     child: Text(
                //       _message,
                //       textAlign: TextAlign.center,
                //       style: TextStyle(
                //         color: _isSuccessMessage ? Colors.green.shade700 : theme.colorScheme.error,
                //         fontSize: 14,
                //       ),
                //     ),
                //   ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : Text(
                    'SIGN UP',
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}