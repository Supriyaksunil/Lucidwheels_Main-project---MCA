import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_card.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _pageBackground = Color(0xFFF6F8FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const Color _cardBorder = Color(0xFFD7E1FF);
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5FF)],
  );
  static const LinearGradient _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
  );

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _AuthHeader(
                        title: 'Welcome back',
                        subtitle: 'Sign in to continue your safety monitoring.',
                        icon: Icons.verified_user_rounded,
                      ),
                      const SizedBox(height: 16),
                      CustomCard(
                        color: Colors.white,
                        gradient: _cardGradient,
                        border: const Border.fromBorderSide(
                          BorderSide(color: _cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(color: _primaryText),
                              validator: Validators.validateEmail,
                              decoration: _inputDecoration(
                                label: 'Email',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(color: _primaryText),
                              validator: Validators.validatePassword,
                              decoration: _inputDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _primaryText,
                                  ),
                                ),
                              ),
                            ),
                            if (authProvider.error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  authProvider.error!,
                                  style:
                                      const TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            CustomButton(
                              label: 'Sign In',
                              icon: Icons.login_rounded,
                              isLoading: authProvider.isLoading,
                              onPressed: () => _login(authProvider),
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFD5DDF9),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(color: _secondaryText),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFD5DDF9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _signInWithGoogle(authProvider),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryText,
                                side: const BorderSide(color: _cardBorder),
                                backgroundColor: Colors.white,
                              ),
                              icon: SvgPicture.asset(
                                'assets/images/google_logo.svg',
                                height: 20,
                              ),
                              label: const Text('Continue with Google'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: _primaryText),
                        child: const Text('Don\'t have an account? Create one'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _secondaryText),
      prefixIcon: Icon(icon, color: _primaryText),
      filled: true,
      fillColor: const Color(0xFFF4F7FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryText),
      ),
    );
  }

  Future<void> _signInWithGoogle(AuthProvider authProvider) async {
    final success = await authProvider.signInWithGoogle();
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _login(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _AuthHeader extends StatelessWidget {
  static const Color _cardBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const LinearGradient _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
  );

  final String title;
  final String subtitle;
  final IconData icon;

  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: Colors.white,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 3, 4, 104),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: _secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
