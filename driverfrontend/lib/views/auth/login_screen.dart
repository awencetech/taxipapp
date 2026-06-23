import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'signup_screen.dart';
import 'google_onboarding_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPhoneLogin = true;
  bool _showOTPField = false;

  @override
  void initState() {
    super.initState();
    // Add listener to phone number field
    _phoneController.addListener(() {
      // If phone number is 10 digits long and we're not already showing OTP, auto-show OTP screen
      final phone = _phoneController.text.trim();
      if (phone.length == 10 && !_showOTPField) {
        // Auto-send OTP or just switch to OTP screen? Let's just switch to OTP screen
        // Wait, the user said "if the number will be entered the otp screen will be shown"
        // Let's show OTP screen when 10 digits are entered
        setState(() {
          _showOTPField = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    if (_isPhoneLogin && !_showOTPField) {
      // Step 1: Request OTP
      final success = await authViewModel.sendOTP(_phoneController.text.trim());
      if (success && mounted) {
        setState(() {
          _showOTPField = true;
        });
      }
      return;
    }

    // Step 2: Verify OTP or Email Login
    bool success;
    if (_isPhoneLogin) {
      if (_otpController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter OTP')),
        );
        return;
      }
      success = await authViewModel.verifyPhoneOTP(
        _phoneController.text.trim(),
        _otpController.text.trim(),
      );
    } else {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
        return;
      }

      success = await authViewModel.login(email, password);
    }

    if (success && mounted) {
      debugPrint('LoginScreen: Login successful, navigating to HomeScreen');
      // Explicitly navigate to HomeScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.error ?? 'Action Failed')),
      );
    }
  }

  void _handleGoogleLogin() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final result = await authViewModel.loginWithGoogle();

    if (result['success'] && mounted) {
      if (result['isNewUser']) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GoogleOnboardingScreen()),
        );
      } else {
        debugPrint('LoginScreen: Google login successful, navigating to HomeScreen');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.error ?? 'Google Login Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient
            Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
                ),
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
                            'TaxiNanban Driver',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Start earning today',
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
                    'Login to start accepting rides',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Login/OTP Card
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
                child: _showOTPField 
                  ? _buildOTPScreen(authViewModel) 
                  : _buildLoginScreen(authViewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginScreen(AuthViewModel authViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Driver Login',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your preferred login method',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Toggle Switch
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              _buildToggleButton('Phone', _isPhoneLogin, () => setState(() => _isPhoneLogin = true)),
              _buildToggleButton('Email', !_isPhoneLogin, () => setState(() => _isPhoneLogin = false)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Dynamic Fields
        if (_isPhoneLogin) ...[
          const Text('Mobile Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '9876543210'),
                ),
              ),
            ],
          ),
        ] else ...[
          const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'driver@taxinanban.com'),
          ),
          const SizedBox(height: 16),
          const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: '********',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: authViewModel.isLoading ? null : _handleLogin,
            child: authViewModel.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isPhoneLogin ? Icons.phone_android : Icons.login),
                      const SizedBox(width: 8),
                      Text(_isPhoneLogin ? 'Send OTP' : 'Login'),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR CONTINUE WITH', style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),

        const SizedBox(height: 24),

        // Social Buttons
        Row(
          children: [
            Expanded(
              child: _buildSocialButton('Google', Icons.g_mobiledata, Colors.red, _handleGoogleLogin),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Register Link
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600])),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Register as Driver', style: TextStyle(color: Color(0xFFFF6D00), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPScreen(AuthViewModel authViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: () => setState(() => _showOTPField = false),
            ),
            const SizedBox(width: 8),
            const Text(
              'Enter OTP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Enter 6-digit OTP',
            style: TextStyle(fontSize: 22, color: Color(0xFF666666), letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'OTP sent to +91 ${_phoneController.text}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12),
          decoration: InputDecoration(
            counterText: "",
            hintText: '******',
            hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: authViewModel.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: authViewModel.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Verify & Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}


