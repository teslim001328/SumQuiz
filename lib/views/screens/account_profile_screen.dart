import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../widgets/pro_status_widget.dart';

/// Modern account profile screen with improved layout and organization
/// Shows user information, account actions, and premium status in a clean interface
class AccountProfileScreen extends StatelessWidget {
  const AccountProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final authService = context.read<AuthService>();
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: <Widget>[
            _buildHeader(context, user),
            const SizedBox(height: 30),
            const ProStatusWidget(),
            const SizedBox(height: 30),
            _buildAccountActions(context, authService, user),
            const SizedBox(height: 30),
            _buildSignOutButton(context, authService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 3,
            ),
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: theme.colorScheme.surface,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          user.displayName,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          user.email,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 8),
        if (user.subscriptionExpiry != null)
          Text(
            'Pro Until: ${user.subscriptionExpiry!.toLocal().toString().split(' ')[0]}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
      ],
    );
  }

  Widget _buildAccountActions(
      BuildContext context, AuthService authService, UserModel user) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor,
      child: Column(
        children: [
          _buildListTile(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Send password reset email',
            onTap: () {
              authService.sendPasswordResetEmail(user.email);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset email sent.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildListTile(
            context,
            icon: Icons.email_outlined,
            title: 'Update Email',
            subtitle: 'Change your email address',
            onTap: () {
              // TODO: Implement email update functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email update coming soon'),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildListTile(
            context,
            icon: Icons.delete_outline,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            onTap: () => _showDeleteAccountDialog(context, authService),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon,
          color: isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.secondary),
      title: Text(title,
          style: theme.textTheme.titleMedium?.copyWith(
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.textTheme.titleMedium?.color)),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: isDestructive
                  ? theme.colorScheme.error.withOpacity(0.7)
                  : theme.textTheme.bodySmall?.color)),
      trailing: Icon(Icons.arrow_forward_ios,
          color:
              isDestructive ? theme.colorScheme.error : theme.iconTheme.color,
          size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: theme.colorScheme.error)),
          content: Text(
              'Are you sure you want to permanently delete your account? This action cannot be undone.',
              style: theme.textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete',
                  style: TextStyle(color: theme.colorScheme.error)),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement actual account deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion coming soon'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthService authService) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        onPressed: () {
          authService.signOut();
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
        ),
      ),
    );
  }
}
