import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/notification_service.dart';
import 'account_screen.dart';
import 'preferences_screen.dart';
import 'data_storage_screen.dart';
import 'subscription_screen.dart';
import 'privacy_about_screen.dart';

class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingsCard(context, 'Account', 'Manage your profile and login info', const AccountScreen()),
            const SizedBox(height: 16),
            _buildSettingsCard(context, 'Preferences', 'Adjust app experience', const PreferencesScreen()),
            const SizedBox(height: 16),
            _buildSettingsCard(context, 'Data & Storage', 'Manage offline files and cache', const DataStorageScreen()),
            const SizedBox(height: 16),
            _buildSettingsCard(context, 'Subscription', 'View your plan & upgrade', const SubscriptionScreen()),
            const SizedBox(height: 16),
            _buildSettingsCard(context, 'Privacy & About', 'Legal, support & app info', const PrivacyAboutScreen()),
            const SizedBox(height: 16),
            _buildNotificationCard(context), // New notification card
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, String title, String subtitle, Widget screen) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).iconTheme.color, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      ),
    );
  }

  // New widget for the notification card
  Widget _buildNotificationCard(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text('Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: const Text('Test your notifications'),
        trailing: ElevatedButton(
          child: const Text('Send Test'),
          onPressed: () {
            notificationService.showTestNotification();
          },
        ),
      ),
    );
  }
}
