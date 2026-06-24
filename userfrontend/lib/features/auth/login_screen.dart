import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/primary_button.dart';
import '../../features/booking/home_screen.dart';
import '../../screens/google_onboarding_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.loginWithGoogle();

    if (mounted) {
      if (result['success'] == true) {
        if (result['isNewUser'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GoogleOnboardingScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Google sign in failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _login() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.local_taxi, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.grey600),
              ),
              const SizedBox(height: 48),
              const Text(
                'Login to your account',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.grey600),
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      const Icon(Icons.lock_outlined, color: AppColors.grey600),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.grey600),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen())),
                  child: const Text('Forgot Password?',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                  text: 'Login',
                  isLoading: authProvider.isLoading,
                  onPressed: _login),
              const SizedBox(height: 32),
              const Row(
                children: [
                  Expanded(
                      child: Divider(color: AppColors.grey300, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR',
                        style: TextStyle(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                      child: Divider(color: AppColors.grey300, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _handleGoogleSignIn,
                icon: const Icon(Icons.login, color: AppColors.black, size: 20),
                label: const Text('Sign in with Google',
                    style: TextStyle(
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.grey300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: AppColors.grey600, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupScreen())),
                    child: const Text('Sign Up',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
