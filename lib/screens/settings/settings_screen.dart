import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../admin/admin_login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openAdmin(BuildContext context) async {
    final loggedIn = await isAdminLoggedIn();
    if (!context.mounted) return;
    if (loggedIn) {
      Navigator.pushNamed(context, '/admin-orders');
    } else {
      Navigator.pushNamed(context, '/admin-login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(
            icon: Icons.admin_panel_settings,
            title: 'Restaurant Admin',
            onTap: () => _openAdmin(context),
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showInfo(context, 'Privacy Policy',
                'We value your privacy. Your personal information is kept secure and never shared with third parties without your consent.'),
          ),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms of Use',
            onTap: () => _showInfo(context, 'Terms of Use',
                'By using this app, you agree to our terms. All orders are subject to availability. Prices may vary without prior notice.'),
          ),
          _buildMenuItem(
            icon: Icons.restaurant_outlined,
            title: 'About Restaurant',
            onTap: () => _showInfo(context, 'About Pawan Biryani',
                'Pawan Biryani has been serving delicious biryani and authentic Indian cuisine since 2010. We use only the freshest ingredients and traditional recipes to bring you the best dining experience.'),
          ),
          _buildMenuItem(
            icon: Icons.contact_support_outlined,
            title: 'Contact',
            onTap: () => _showInfo(context, 'Contact Us',
                'Phone: +91 98765 43210\nEmail: info@pawanbiryani.com\nAddress: 123, MG Road, Indore, MP'),
          ),
          const Divider(height: 32),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              AppConstants.appName,
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _AboutSection(),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Made with ❤️ by',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'YASH KUMAR\nor also know as BIPUL KUMAR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.email_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        'yash.webstudio@gmail.com',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
