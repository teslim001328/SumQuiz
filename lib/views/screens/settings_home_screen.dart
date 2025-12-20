import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/services/notification_service.dart';

/// Modern settings home screen with improved visual design and navigation
/// Provides access to all app settings in a clean, organized interface
class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle(context, 'Account'),
            _buildSettingsCard(
              context,
              icon: Icons.account_circle,
              title: 'Account',
              subtitle: 'Manage your profile and login info',
              onTap: () => context.push('/account-profile'),
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              context,
              icon: Icons.security,
              title: 'Privacy & About',
              subtitle: 'Legal, support & app info',
              onTap: () => context.push('/settings/privacy-about'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Preferences'),
            _buildSettingsCard(
              context,
              icon: Icons.palette,
              title: 'Display',
              subtitle: 'Adjust app appearance and theme',
              onTap: () => context.push('/settings/preferences'),
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              context,
              icon: Icons.storage,
              title: 'Data & Storage',
              subtitle: 'Manage offline files and cache',
              onTap: () => context.push('/settings/data-storage'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Premium Features'),
            _buildSettingsCard(
              context,
              icon: Icons.workspace_premium_outlined,
              title: 'Subscription',
              subtitle: 'View your plan & upgrade',
              onTap: () => context.push('/subscription'),
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              context,
              icon: Icons.card_giftcard,
              title: 'Refer a Friend',
              subtitle: 'Get rewards for inviting friends',
              onTap: () => context.push('/referral'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Utilities'),
            _buildNotificationCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
        title: Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color)),
        trailing: Icon(Icons.arrow_forward_ios,
            color: theme.iconTheme.color, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.notifications_outlined,
              color: theme.colorScheme.primary, size: 24),
        ),
        title: Text('Notifications',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('Test your notifications',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Send Test'),
          onPressed: () {
            notificationService.showTestNotification();
          },
        ),
      ),
    );
  }
}
