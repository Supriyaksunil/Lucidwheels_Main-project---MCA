import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_card.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.personal;
  bool _obscurePassword = true;
  bool _isEmergencyContactRegistration = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryText,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _pageGradient),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _AuthHeader(
                        title: 'Create Account',
                        subtitle: 'Set up LucidWheels in a minute.',
                        icon: Icons.person_add_alt_1_rounded,
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
                              controller: _firstNameController,
                              validator: (value) =>
                                  Validators.validateName(value, 'First name'),
                              style: const TextStyle(color: _primaryText),
                              decoration: _inputDecoration(
                                label: 'First Name *',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _middleNameController,
                              style: const TextStyle(color: _primaryText),
                              decoration: _inputDecoration(
                                label: 'Middle Name (Optional)',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _lastNameController,
                              validator: (value) =>
                                  Validators.validateName(value, 'Last name'),
                              style: const TextStyle(color: _primaryText),
                              decoration: _inputDecoration(
                                label: 'Last Name *',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                              style: const TextStyle(color: _primaryText),
                              decoration: _inputDecoration(
                                label: 'Email *',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: Validators.validatePhone,
                              style: const TextStyle(color: _primaryText),
                              decoration: _inputDecoration(
                                label: 'Phone *',
                                icon: Icons.call_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: Validators.validatePassword,
                              style: const TextStyle(color: _primaryText),
                              decoration: _inputDecoration(
                                label: 'Password *',
                                icon: Icons.lock_outline_rounded,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _primaryText,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Are you an emergency contact of someone?',
                              style: TextStyle(
                                color: _primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  selected: !_isEmergencyContactRegistration,
                                  label: const Text('No'),
                                  onSelected: (_) =>
                                      _setEmergencyContactRegistration(false),
                                  selectedColor:
                                      const Color.fromARGB(255, 3, 4, 104),
                                  labelStyle: TextStyle(
                                    color: !_isEmergencyContactRegistration
                                        ? Colors.white
                                        : const Color.fromARGB(255, 3, 4, 104),
                                    fontWeight: !_isEmergencyContactRegistration
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                  backgroundColor: const Color(0xFFEAF0FF),
                                  side: BorderSide(
                                    color: !_isEmergencyContactRegistration
                                        ? const Color.fromARGB(255, 3, 4, 104)
                                        : const Color(0xFFD7E1FF),
                                  ),
                                ),
                                ChoiceChip(
                                  selected: _isEmergencyContactRegistration,
                                  label: const Text('Yes'),
                                  onSelected: (_) =>
                                      _setEmergencyContactRegistration(true),
                                  selectedColor: AppTheme.accentRed,
                                  labelStyle: TextStyle(
                                    color: _isEmergencyContactRegistration
                                        ? Colors.white
                                        : AppTheme.accentRed,
                                    fontWeight: _isEmergencyContactRegistration
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                  backgroundColor: const Color(0xFFFFECE8),
                                  side: BorderSide(
                                    color: _isEmergencyContactRegistration
                                        ? AppTheme.accentRed
                                        : const Color(0xFFFFCFC4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isEmergencyContactRegistration
                                    ? const Color(0xFFFFF2EE)
                                    : const Color(0xFFF4F7FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isEmergencyContactRegistration
                                      ? const Color(0xFFFFCFC4)
                                      : _cardBorder,
                                ),
                              ),
                              child: Text(
                                _isEmergencyContactRegistration
                                    ? 'This account will register as an Emergency Contact and receive live emergency alerts with driver location.'
                                    : 'Choose a primary app role below if you are not registering as an emergency contact.',
                                style: const TextStyle(color: _secondaryText),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (!_isEmergencyContactRegistration) ...[
                              const Text(
                                'Select role',
                                style: TextStyle(
                                  color: _primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _RoleChoice(
                                selected: _selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                },
                              ),
                            ] else ...[
                              const Text(
                                'Role: Emergency Contact',
                                style: TextStyle(
                                  color: AppTheme.accentRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
                              label: 'Register',
                              icon: Icons.how_to_reg_rounded,
                              isLoading: authProvider.isLoading,
                              onPressed: () => _register(authProvider),
                            ),
                          ],
                        ),
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
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

  void _setEmergencyContactRegistration(bool isEmergencyContact) {
    setState(() {
      _isEmergencyContactRegistration = isEmergencyContact;
      if (isEmergencyContact) {
        _selectedRole = UserRole.emergencyContact;
      } else if (_selectedRole == UserRole.emergencyContact) {
        _selectedRole = UserRole.personal;
      }
    });
  }

  Future<void> _register(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        firstName,
        middleName.isNotEmpty ? middleName : null,
        lastName,
        _phoneController.text.trim(),
        _selectedRole,
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
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

class _RoleChoice extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  const _RoleChoice({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _roleChip('Personal', UserRole.personal),
        _roleChip('Commercial', UserRole.commercial),
        _roleChip('Fleet Manager', UserRole.fleetManager),
      ],
    );
  }

  Widget _roleChip(String label, UserRole value) {
    final isSelected = value == selected;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onChanged(value),
      selectedColor: const Color.fromARGB(255, 3, 4, 104),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color.fromARGB(255, 3, 4, 104),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      ),
      backgroundColor: const Color(0xFFEAF0FF),
      side: BorderSide(
        color: isSelected
            ? const Color.fromARGB(255, 3, 4, 104)
            : const Color(0xFFD7E1FF),
      ),
    );
  }
}
