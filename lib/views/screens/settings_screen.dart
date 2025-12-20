import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/views/widgets/pro_gate.dart';

/// Modern, intuitive settings screen with improved organization and visual hierarchy
/// Groups related settings together and provides clear visual cues for premium features
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              _buildSectionTitle(context, 'Account'),
              _buildSettingsCard(
                context,
                icon: Icons.account_circle,
                title: 'Account',
                subtitle: 'Manage your profile and login info',
                onTap: () => context.push('/account-profile'),
              ),
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
              _buildSettingsCard(
                context,
                icon: Icons.storage,
                title: 'Data & Storage',
                subtitle: 'Manage offline files and cache',
                onTap: () => context.push('/settings/data-storage'),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Premium Features'),
              _buildSubscriptionCard(context),
              const SizedBox(height: 16),
              _buildReferralCard(context),
            ],
          ),
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

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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

  Widget _buildSubscriptionCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/subscription'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium_outlined,
                    color: theme.colorScheme.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SumQuiz Pro',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unlock all features and study without limits.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onPrimaryContainer, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/referral'),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.card_giftcard,
              color: theme.colorScheme.secondary, size: 24),
        ),
        title: Text('Refer a Friend',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('Get rewards for inviting friends',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color)),
        trailing: Icon(Icons.arrow_forward_ios,
            color: theme.iconTheme.color, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
