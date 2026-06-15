import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient
            Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TaxiNanban Vendor',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Manage your fleet today',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to manage your fleet',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Login Card
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Vendor Login',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your credentials to access your account',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Email Field
                      const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'vendor@taxinanban.com'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '********',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authViewModel.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    final success = await authViewModel.login(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                    if (success && mounted) {
                                      if (!context.mounted) return;
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                      );
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(authViewModel.errorMessage ?? 'Login Failed')),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: authViewModel.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login),
                                    const SizedBox(width: 8),
                                    const Text('Login'),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Terms Text
                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
