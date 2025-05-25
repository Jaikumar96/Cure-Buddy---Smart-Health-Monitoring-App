import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart'; // Assuming this path is correct
import 'register_patient_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void handleLogin() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Basic client-side validation
    if (emailController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter your email.');
      return;
    }
    if (passwordController.text.isEmpty) {
      setState(() => errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = ''; // Clear old error
    });

    try {
      final data = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );
      final token = data['token'];

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() => errorMessage =
              data['message'] ?? 'Login failed: No token received.');
        }
        return;
      }

      if (token.toString().contains("Doctor registration not verified")) {
        if (mounted) {
          setState(() => errorMessage = token.toString());
        }
        return;
      }

      // 🔐 Save JWT token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      // 🔍 Decode and navigate based on role
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      String role = decodedToken['role'];
      print("Decoded Role: $role"); // For debugging, consider removing in production

      if (!mounted) return;

      switch (role) {
        case 'PATIENT':
          Navigator.pushReplacementNamed(context, '/patient-dashboard');
          break;
        case 'DOCTOR':
          Navigator.pushReplacementNamed(context, '/doctor-dashboard');
          break;
        case 'ADMIN':
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
          break;
        default:
          setState(() => errorMessage =
          'Login successful, but role "$role" is unsupported.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Login Error: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white, // Or theme.scaffoldBackgroundColor for consistency
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40), // Adjusted spacing
              Image.asset(
                'assets/doctor_login.gif', // Ensure this asset exists in your pubspec.yaml
                height: 200, // Adjusted height
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.login, size: 150, color: theme.colorScheme.primary.withOpacity(0.7));
                },
              ),
              const SizedBox(height: 30),
              Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : handleLogin(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              ),
              const SizedBox(height: 16),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : handleLogin,
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
                  'SIGN IN',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterPatientScreen(),
                    ),
                  );
                },
                child: Text(
                  "Don't have an account? Register as Patient",
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 30), // For some bottom padding
            ],
          ),
        ),
      ),
    );
  }
}