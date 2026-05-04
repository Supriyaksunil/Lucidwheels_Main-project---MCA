import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart' show AuthProvider;
import '../providers/fleet_provider.dart';
import '../providers/monitoring_provider.dart';
import '../services/call_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/common/animated_reveal.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_card.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_indicator.dart';
import 'about_lucidwheels_screen.dart';
import 'emergency_alerts_screen.dart';
import 'help_support_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _pageBackground = Color(0xFFF6F8FF);
  static const Color _cardBackground = Colors.white;
  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return AppScaffold(
      title: 'Profile',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: _primaryText,
      appBarTitleTextStyle: const TextStyle(
        color: _primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          children: [
            AnimatedReveal(
              delay: const Duration(milliseconds: 40),
              child: _buildProfileHeader(user, context),
            ),
            const SizedBox(height: 16),
            AnimatedReveal(
              delay: const Duration(milliseconds: 120),
              child: _buildInfoSection(user),
            ),
            if (user?.role == UserRole.commercial) ...[
              const SizedBox(height: 16),
              AnimatedReveal(
                delay: const Duration(milliseconds: 160),
                child: _CommercialFleetLinkCard(user: user!),
              ),
            ],
            if (user?.role == UserRole.personal ||
                user?.role == UserRole.commercial) ...[
              const SizedBox(height: 16),
              AnimatedReveal(
                delay: const Duration(milliseconds: 200),
                child: _buildEmergencyContacts(user, context),
              ),
            ],
            const SizedBox(height: 16),
            AnimatedReveal(
              delay: const Duration(milliseconds: 280),
              child: _buildSettingsSection(context),
            ),
            const SizedBox(height: 16),
            AnimatedReveal(
              delay: const Duration(milliseconds: 360),
              child: _buildLogoutButton(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user, BuildContext context) {
    return CustomCard(
      color: _cardBackground,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildProfileAvatar(user),
              Positioned(
                right: -6,
                bottom: -6,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(
                    side: BorderSide(color: _softBorder),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _pickProfileImage(context),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: _primaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user?.name ?? 'User',
            style: const TextStyle(
              color: _primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(color: _secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 10),
          StatusIndicator(
            label:
                (user?.role.toString().split('.').last ?? 'USER').toUpperCase(),
            icon: Icons.verified_rounded,
            color: _primaryText,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel? user) {
    final imagePath = user?.profileImagePath;
    final dataImageBytes = _decodeDataImage(imagePath);
    final imageFile = (!kIsWeb && imagePath != null && imagePath.isNotEmpty)
        ? File(imagePath)
        : null;
    final hasFileImage = imageFile != null && imageFile.existsSync();
    final hasWebImage = kIsWeb &&
        imagePath != null &&
        imagePath.isNotEmpty &&
        dataImageBytes == null;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: AppTheme.primaryBlue,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: dataImageBytes != null
            ? Image.memory(
                dataImageBytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
                    size: 52, color: Colors.white),
              )
            : hasWebImage
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  )
                : hasFileImage
                    ? Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_rounded,
                        size: 52, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoSection(UserModel? user) {
    return CustomCard(
      color: _cardBackground,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Account Info',
            subtitle: 'Your essential details',
            leadingIcon: Icons.badge_rounded,
            titleColor: _primaryText,
            subtitleColor: _secondaryText,
            iconColor: _primaryText,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.call_rounded, 'Phone', user?.phone ?? 'Not set'),
          Divider(color: _primaryText.withValues(alpha: 0.14)),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Member Since',
            user?.createdAt.toString().split(' ')[0] ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _secondaryText)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts(UserModel? user, BuildContext context) {
    return CustomCard(
      color: _cardBackground,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Emergency Contacts',
            subtitle: 'People to notify quickly',
            leadingIcon: Icons.contact_emergency_rounded,
            actionLabel: 'Add',
            titleColor: _primaryText,
            subtitleColor: _secondaryText,
            iconColor: _primaryText,
            actionColor: _primaryText,
            onAction: () => _showAddContactDialog(context),
          ),
          const SizedBox(height: 10),
          if (user?.emergencyContacts.isEmpty ?? true)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No emergency contacts added yet.',
                style: TextStyle(color: _secondaryText),
              ),
            )
          else
            ...user!.emergencyContacts
                .map((contact) => _buildContactItem(context, contact)),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, EmergencyContact contact) {
    final relationship = contact.relationship.trim().isEmpty
        ? 'Emergency Contact'
        : contact.relationship.trim();
    final phoneLabel =
        contact.phone.trim().isEmpty ? 'No phone number' : contact.phone.trim();
    final emailLabel = contact.email?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAFF), Color(0xFFEFF4FF)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _softBorder),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      color: _primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$relationship - $phoneLabel',
                    style: const TextStyle(color: _secondaryText, fontSize: 12),
                  ),
                  if (emailLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      emailLabel,
                      style:
                          const TextStyle(color: _secondaryText, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call_rounded, color: _primaryText),
              onPressed: contact.phone.trim().isEmpty
                  ? null
                  : () => _callEmergencyContact(context, contact.phone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return CustomCard(
      color: _cardBackground,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        children: [
          _buildSettingsTile(
            Icons.notifications_active_rounded,
            'Emergency Alerts',
            () => _openScreen(context, const EmergencyAlertsScreen()),
          ),
          _buildSettingsTile(
            Icons.help_center_rounded,
            'Help & Support',
            () => _openScreen(context, const HelpSupportScreen()),
          ),
          _buildSettingsTile(
            Icons.info_outline_rounded,
            'About LucidWheels',
            () => _openScreen(context, const AboutLucidWheelsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _primaryText),
      title: Text(
        title,
        style: const TextStyle(
          color: _primaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: _secondaryText),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider provider) {
    return CustomButton(
      label: 'Logout',
      icon: Icons.logout_rounded,
      backgroundColor: AppTheme.accentRed,
      foregroundColor: Colors.white,
      onPressed: () async {
        final monitoringProvider = Provider.of<MonitoringProvider>(
          context,
          listen: false,
        );
        if (monitoringProvider.isMonitoring) {
          await monitoringProvider.stopMonitoring();
        } else {
          await monitoringProvider.clearTransientState();
        }
        await provider.logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
    );
  }

  Future<void> _pickProfileImage(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to update photo. Please login again.')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final selectedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 720,
        maxHeight: 720,
      );

      if (selectedImage == null) {
        return;
      }

      final profileImageValue = kIsWeb
          ? 'data:image/jpeg;base64,${base64Encode(await selectedImage.readAsBytes())}'
          : selectedImage.path;

      await authProvider.updateUser(
        user.copyWith(profileImagePath: profileImageValue),
      );

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not pick image. Please try again.'),
        ),
      );
    }
  }

  Uint8List? _decodeDataImage(String? source) {
    if (source == null || !source.startsWith('data:image')) {
      return null;
    }
    final splitIndex = source.indexOf(',');
    if (splitIndex == -1 || splitIndex >= source.length - 1) {
      return null;
    }

    try {
      return base64Decode(source.substring(splitIndex + 1));
    } catch (_) {
      return null;
    }
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _callEmergencyContact(
    BuildContext context,
    String phoneNumber,
  ) async {
    if (phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No phone number available for this contact.')),
      );
      return;
    }

    await CallService().callEmergencyContacts(
      [phoneNumber],
      delay: Duration.zero,
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final relationController = TextEditingController();

    InputDecoration fieldDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _secondaryText),
        prefixIcon: Icon(icon, color: _primaryText),
        filled: true,
        fillColor: const Color(0xFFF4F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryText),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        scrollable: true,
        title: const Text(
          'Add Emergency Contact',
          style: TextStyle(color: _primaryText),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: _primaryText),
                decoration:
                    fieldDecoration('Name', Icons.person_outline_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: _primaryText),
                keyboardType: TextInputType.phone,
                decoration: fieldDecoration('Phone', Icons.phone_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                style: const TextStyle(color: _primaryText),
                keyboardType: TextInputType.emailAddress,
                decoration: fieldDecoration('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                style: const TextStyle(color: _primaryText),
                decoration: fieldDecoration(
                    'Relationship', Icons.people_outline_rounded),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _primaryText),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Add',
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final user = authProvider.currentUser;

              if (user != null) {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final email = emailController.text.trim().toLowerCase();
                final relationship = relationController.text.trim();

                if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter name, phone number, and email address.',
                      ),
                    ),
                  );
                  return;
                }

                final emailValidationError = Validators.validateEmail(email);
                if (emailValidationError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(emailValidationError)),
                  );
                  return;
                }

                final linkedUser =
                    await FirebaseService().findEmergencyContactUser(
                  name: name,
                  phone: phone,
                  email: email,
                );
                final newContact = EmergencyContact(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  phone: phone,
                  email: email,
                  relationship:
                      relationship.isEmpty ? 'Emergency Contact' : relationship,
                  userId: linkedUser?.uid,
                );

                final updatedContacts =
                    List<EmergencyContact>.from(user.emergencyContacts)
                      ..add(newContact);

                final updatedUser = user.copyWith(
                  emergencyContacts: updatedContacts,
                );

                await authProvider.updateUser(updatedUser);
              }

              if (!context.mounted) {
                return;
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _CommercialFleetLinkCard extends StatefulWidget {
  const _CommercialFleetLinkCard({required this.user});

  final UserModel user;

  @override
  State<_CommercialFleetLinkCard> createState() =>
      _CommercialFleetLinkCardState();
}

class _CommercialFleetLinkCardState extends State<_CommercialFleetLinkCard> {
  final TextEditingController _driverCodeController = TextEditingController();
  String? _joiningFleetId;
  bool _isJoiningByCode = false;

  @override
  void dispose() {
    _driverCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fleetProvider = context.watch<FleetProvider>();
    final invitations = fleetProvider.commercialInvitations;

    return CustomCard(
      color: ProfileScreen._cardBackground,
      gradient: ProfileScreen._cardGradient,
      border: const Border.fromBorderSide(
        BorderSide(color: ProfileScreen._softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Fleet Invitations',
            subtitle:
                'Your fleet manager can add you by email, or you can join directly with the 10-digit driver ID',
            leadingIcon: Icons.route_rounded,
            titleColor: ProfileScreen._primaryText,
            subtitleColor: ProfileScreen._secondaryText,
            iconColor: ProfileScreen._primaryText,
          ),
          const SizedBox(height: 12),
          Text(
            'Linked fleets: ${widget.user.linkedFleetIds.length}',
            style: const TextStyle(color: ProfileScreen._secondaryText),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7FAFF), Color(0xFFEFF4FF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ProfileScreen._softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Have a driver ID?',
                  style: TextStyle(
                    color: ProfileScreen._primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter the 10-digit ID from your fleet manager if the invite email was wrong or the invite is missing.',
                  style: TextStyle(color: ProfileScreen._secondaryText),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _driverCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  style: const TextStyle(color: ProfileScreen._primaryText),
                  decoration: const InputDecoration(
                    labelText: 'Driver ID',
                    counterText: '',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Join With ID',
                    icon: Icons.link_rounded,
                    isLoading: _isJoiningByCode,
                    onPressed: _joinWithDriverCode,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (fleetProvider.isLoading && invitations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (invitations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No fleet invitations available yet. Ask your fleet manager to add your email address in the fleet, or use the driver ID above.',
                style: TextStyle(color: ProfileScreen._secondaryText),
              ),
            )
          else
            ...invitations.map(
              (invitation) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FleetInvitationCard(
                  invitation: invitation,
                  isJoining: _joiningFleetId == invitation.fleetId,
                  onJoin: invitation.isJoined
                      ? null
                      : () => _joinInvitation(invitation),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _joinWithDriverCode() async {
    final driverCode = _driverCodeController.text.trim();
    if (driverCode.length != 10) {
      _showMessage('Enter the 10-digit driver ID from your fleet manager');
      return;
    }

    setState(() => _isJoiningByCode = true);
    try {
      final fleetProvider = context.read<FleetProvider>();
      final authProvider = context.read<AuthProvider>();
      final joinedCount = await fleetProvider.joinFleetWithDriverCode(
        driverCode,
      );
      await authProvider.refreshCurrentUser();
      if (!mounted) {
        return;
      }
      _driverCodeController.clear();
      _showMessage(
        joinedCount == 1
            ? 'Joined fleet successfully'
            : 'Joined $joinedCount fleets successfully',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _isJoiningByCode = false);
      }
    }
  }

  Future<void> _joinInvitation(FleetInvitation invitation) async {
    setState(() => _joiningFleetId = invitation.fleetId);
    try {
      final fleetProvider = context.read<FleetProvider>();
      final authProvider = context.read<AuthProvider>();
      await fleetProvider.joinFleetInvitation(invitation);
      await authProvider.refreshCurrentUser();
      if (!mounted) {
        return;
      }
      _showMessage('Joined ${invitation.fleetName} successfully');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _joiningFleetId = null);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }
}

class _FleetInvitationCard extends StatelessWidget {
  const _FleetInvitationCard({
    required this.invitation,
    required this.isJoining,
    this.onJoin,
  });

  final FleetInvitation invitation;
  final bool isJoining;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FAFF), Color(0xFFEFF4FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProfileScreen._softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invitation.fleetName,
            style: const TextStyle(
              color: ProfileScreen._primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fleet Manager: ${invitation.managerName}',
            style: const TextStyle(color: ProfileScreen._secondaryText),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: invitation.isJoined
                      ? const Color(0xFFE5F7EE)
                      : const Color(0xFFFDEDCF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  invitation.isJoined ? 'Joined' : 'Pending Invite',
                  style: TextStyle(
                    color: invitation.isJoined
                        ? const Color(0xFF1C7D4D)
                        : const Color(0xFF8A5A00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (invitation.isJoined)
                const Text(
                  'Fleet linked successfully',
                  style: TextStyle(color: ProfileScreen._secondaryText),
                )
              else
                SizedBox(
                  width: 148,
                  child: CustomButton(
                    label: 'Join Fleet',
                    icon: Icons.link_rounded,
                    isLoading: isJoining,
                    onPressed: onJoin,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
