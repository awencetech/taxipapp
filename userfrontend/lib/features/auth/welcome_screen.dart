import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../screens/google_onboarding_screen.dart';
import '../booking/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _opacityAnimation,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_taxi,
                              size: 64,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _opacityAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: const Text(
                            "Welcome to\nTaxiNanban",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.card,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: _opacityAnimation,
                        child: Text(
                          AppConstants.appTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.card.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.card,
                            foregroundColor: AppColors.primary,
                            elevation: 8,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignupScreen()),
                            );
                          },
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.card.withValues(alpha: 0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Or continue with",
                              style: TextStyle(
                                color: AppColors.card.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.card.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.card,
                            side: BorderSide(
                              color: AppColors.card.withValues(alpha: 0.2),
                            ),
                          ),
                          icon: const Icon(Icons.login),
                          onPressed: _handleGoogleSignIn,
                          label: const Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Continue as Guest",
                          style: TextStyle(
                            color: AppColors.card.withValues(alpha: 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
