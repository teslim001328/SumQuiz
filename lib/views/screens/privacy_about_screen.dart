import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modern privacy and about screen with improved layout and additional information
/// Provides access to legal documents, support, and app information
class PrivacyAboutScreen extends StatelessWidget {
  const PrivacyAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Privacy & About',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(context, theme),
                const SizedBox(height: 24),
                _buildLinkCard(
                  context,
                  theme: theme,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we collect and use your data',
                  onTap: () => _launchURL('https://sumquiz.com/privacy'),
                ),
                const SizedBox(height: 16),
                _buildLinkCard(
                  context,
                  theme: theme,
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'Our terms and conditions',
                  onTap: () => _launchURL('https://sumquiz.com/terms'),
                ),
                const SizedBox(height: 16),
                _buildLinkCard(
                  context,
                  theme: theme,
                  icon: Icons.help_outline,
                  title: 'Support / Contact',
                  subtitle: 'Get help or contact our team',
                  onTap: () => _launchURL('mailto:support@sumquiz.com'),
                ),
                const SizedBox(height: 16),
                _buildLinkCard(
                  context,
                  theme: theme,
                  icon: Icons.info_outline,
                  title: 'Open Source Licenses',
                  subtitle: 'Licenses for third-party components',
                  onTap: () => _showLicenses(context),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'SumQuiz v1.0.0',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: () => _checkForUpdates(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: theme.colorScheme.onSurface),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    ),
                    child: const Text('Check for Updates'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ThemeData theme) {
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shield_outlined,
                      color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About SumQuiz',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your intelligent learning companion',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'SumQuiz helps you learn smarter with AI-powered content creation, '
              'spaced repetition, and personalized study plans.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context,
      {required ThemeData theme,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.iconTheme.color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'SumQuiz',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 SumQuiz. All rights reserved.',
    );
  }

  void _checkForUpdates(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking for updates...',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
        backgroundColor: theme.colorScheme.secondaryContainer,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implement actual update checking
  }
}
