import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_card.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color _pageBackground = Color(0xFFF6F8FF);
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
    return AppScaffold(
      title: 'Help & Support',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: AppTheme.primaryBlue,
      appBarTitleTextStyle: const TextStyle(
        color: AppTheme.primaryBlue,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          children: [
            CustomCard(
              color: Colors.white,
              gradient: _cardGradient,
              border: const Border.fromBorderSide(
                BorderSide(color: Color(0xFFD7E1FF)),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    context,
                    icon: Icons.mail_outline_rounded,
                    title: 'Email Support',
                    subtitle: 'support@lucidwheels.com',
                    onTap: () => _launch(
                      context,
                      Uri(
                        scheme: 'mailto',
                        path: 'support@lucidwheels.com',
                        query: 'subject=LucidWheels Support',
                      ),
                    ),
                  ),
                  Divider(color: AppTheme.primaryBlue.withValues(alpha: 0.14)),
                  _buildActionTile(
                    context,
                    icon: Icons.phone_in_talk_rounded,
                    title: 'Call Support',
                    subtitle: '+91 1800 123 456',
                    onTap: () => _launch(
                        context, Uri(scheme: 'tel', path: '+911800123456')),
                  ),
                  Divider(color: AppTheme.primaryBlue.withValues(alpha: 0.14)),
                  _buildActionTile(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'FAQ & Troubleshooting',
                    subtitle: 'Read common answers quickly',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text(
                            'Quick FAQs',
                            style: TextStyle(color: AppTheme.primaryBlue),
                          ),
                          content: const Text(
                            '1. Keep camera permissions enabled for monitoring.\n\n'
                            '2. Keep location services ON for incident reports.\n\n'
                            '3. Add emergency contacts from Profile for faster alerts.',
                            style: TextStyle(
                              color: Color(0xFF4D5AA6),
                              height: 1.5,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF4D5AA6)),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF4D5AA6),
      ),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri)) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open support option')),
      );
    }
  }
}
