import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../services/subscription_service.dart';
import '../../models/user_model.dart';

/// Modern subscription screen using RevenueCat native paywalls
/// This is a wrapper that presents the RevenueCat paywall
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserModel?>();
    final subscriptionService = context.watch<SubscriptionService?>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('SumQuiz Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: FutureBuilder<bool>(
          future: _checkProStatus(subscriptionService),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final hasPro = snapshot.data ?? user?.isPro ?? false;

            if (hasPro) {
              // User already has Pro - show subscription management
              return _buildProMemberView(context, theme, subscriptionService);
            }

            // User needs to subscribe - show paywall button
            return _buildUpgradeView(context, theme, subscriptionService);
          },
        ),
      ),
    );
  }

  Future<bool> _checkProStatus(SubscriptionService? service) async {
    if (service == null) return false;
    return await service.hasProAccess();
  }

  Widget _buildUpgradeView(
    BuildContext context,
    ThemeData theme,
    SubscriptionService? subscriptionService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Unlock SumQuiz Pro',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Get unlimited access to all features',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Feature list
          _buildFeatureItem(theme, 'Unlimited quizzes & flashcards'),
          _buildFeatureItem(theme, 'AI-powered question generation'),
          _buildFeatureItem(theme, 'Advanced progress tracking'),
          _buildFeatureItem(theme, 'Ad-free experience'),

          const SizedBox(height: 48),

          // Show Paywall Button
          ElevatedButton(
            onPressed: () => _presentPaywall(context, subscriptionService),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'View Plans',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Restore Purchases
          TextButton(
            onPressed: () => _restorePurchases(context, subscriptionService),
            child: Text(
              'Restore Purchases',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProMemberView(
    BuildContext context,
    ThemeData theme,
    SubscriptionService? subscriptionService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          Text(
            'You\'re a Pro Member!',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enjoy unlimited access to all features',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Show subscription details
          FutureBuilder<SubscriptionDetails?>(
            future: subscriptionService?.getSubscriptionDetails(),
            builder: (context, snapshot) {
              final details = snapshot.data;

              if (details == null) {
                return const SizedBox.shrink();
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(theme, 'Plan', details.productName),
                      const SizedBox(height: 8),
                      _buildDetailRow(theme, 'Status', details.renewalStatus),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          theme, 'Expires', details.formattedExpiry),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Manage Subscription (Customer Center)
          ElevatedButton(
            onPressed: () =>
                _presentCustomerCenter(context, subscriptionService),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Manage Subscription',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 22, color: Colors.green.shade500),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Present RevenueCat native paywall
  Future<void> _presentPaywall(
    BuildContext context,
    SubscriptionService? subscriptionService,
  ) async {
    if (subscriptionService == null) {
      _showError(context, 'Subscription service not available');
      return;
    }

    try {
      final result = await subscriptionService.presentPaywall();

      if (!context.mounted) return;

      switch (result) {
        case PaywallResult.purchased:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to SumQuiz Pro! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case PaywallResult.restored:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored successfully!'),
            ),
          );
          break;
        case PaywallResult.cancelled:
        case PaywallResult.error:
          // User cancelled or error - no action needed
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to show payment options: $e');
      }
    }
  }

  /// Present Customer Center for subscription management
  Future<void> _presentCustomerCenter(
    BuildContext context,
    SubscriptionService? subscriptionService,
  ) async {
    if (subscriptionService == null) {
      _showError(context, 'Subscription service not available');
      return;
    }

    try {
      await subscriptionService.presentCustomerCenter();
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to open management screen: $e');
      }
    }
  }

  /// Restore previous purchases
  Future<void> _restorePurchases(
    BuildContext context,
    SubscriptionService? subscriptionService,
  ) async {
    if (subscriptionService == null) {
      _showError(context, 'Subscription service not available');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await subscriptionService.restorePurchases();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored successfully!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      _showError(context, 'Failed to restore purchases: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
