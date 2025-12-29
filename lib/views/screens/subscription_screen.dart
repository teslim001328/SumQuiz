import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/iap_service.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final iapService = context.watch<IAPService?>();
    final authUser = context.watch<AuthService>().currentUser;
    final isVerified = authUser?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SumQuiz Pro'),
      ),
      body: Column(
        children: [
          if (authUser != null && !isVerified) _buildVerificationWarning(context),
          Expanded(
            child: Center(
              child: FutureBuilder<bool>(
                future: _checkProStatus(iapService),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final hasPro = snapshot.data ?? user?.isPro ?? false;

                  if (hasPro) {
                    return _buildProMemberView(context, iapService);
                  }

                  return _buildUpgradeView(context, iapService);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkProStatus(IAPService? service) async {
    return await service?.hasProAccess() ?? false;
  }

  Widget _buildUpgradeView(BuildContext context, IAPService? iapService) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('Unlock SumQuiz Pro', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Get unlimited access to all features', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 48),
          _buildFeatureList(theme),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => _showIAPProducts(context, iapService),
            child: const Text('View Plans'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _restorePurchases(context, iapService),
            child: Text('Restore Purchases', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildProMemberView(BuildContext context, IAPService? iapService) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified, size: 80, color: Colors.amber),
          const SizedBox(height: 24),
          Text('You\'re a Pro Member!', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Enjoy unlimited access to all features', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pro Benefits', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildFeatureItem(theme, 'Unlimited content generation'),
                  _buildFeatureItem(theme, 'Unlimited folders'),
                  _buildFeatureItem(theme, 'Full Spaced Repetition System'),
                  _buildFeatureItem(theme, 'Progress analytics with exports'),
                  _buildFeatureItem(theme, 'Daily missions with full rewards'),
                  _buildFeatureItem(theme, 'All gamification rewards'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FutureBuilder<List<ProductDetails>?>(
            future: iapService?.getAvailableProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data;
              if (products == null || products.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available Products', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...products.map((product) => _buildProductRow(theme, product)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _presentIAPManagement(context, iapService),
            child: const Text('Manage Subscription'),
          ),
        ],
      ),
    );
  }

  Column _buildFeatureList(ThemeData theme) {
    return Column(
      children: [
        _buildFeatureItem(theme, 'Unlimited content generation (summaries, quizzes, flashcards)'),
        _buildFeatureItem(theme, 'Unlimited folders and AI tagging'),
        _buildFeatureItem(theme, 'Full Spaced Repetition System (unlimited cards)'),
        _buildFeatureItem(theme, 'Progress analytics with charts and exports (PDF/Word)'),
        _buildFeatureItem(theme, 'Daily missions with full rewards'),
        _buildFeatureItem(theme, 'AI Quiz and Flashcards unlimited'),
        _buildFeatureItem(theme, 'Gamification rewards (momentum, streaks, badges)'),
        _buildFeatureItem(theme, 'Edit content functionality'),
      ],
    );
  }

  Widget _buildFeatureItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 22, color: Colors.green.shade500),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildProductRow(ThemeData theme, ProductDetails product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(product.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(product.price, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        const Divider(),
      ],
    );
  }

  Future<void> _showIAPProducts(BuildContext context, IAPService? iapService) async {
    if (iapService == null) {
      _showError(context, 'IAP service not available');
      return;
    }

    try {
      final products = await iapService.getAvailableProducts();
      if (!context.mounted) return;
      if (products.isEmpty) {
        _showError(context, 'No products available');
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose a Plan'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(shrinkWrap: true, children: products.map((p) => _buildProductTile(context, p, iapService)).toList()),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
        ),
      );
    } catch (e) {
      if (context.mounted) _showError(context, 'Failed to load products: $e');
    }
  }

  ListTile _buildProductTile(BuildContext context, ProductDetails product, IAPService iapService) {
    return ListTile(
      title: Text(product.title),
      subtitle: Text(product.description),
      trailing: Text(product.price),
      onTap: () async {
        Navigator.of(context).pop();
        final success = await iapService.purchaseProduct(product.id);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to SumQuiz Pro! 🎉'), backgroundColor: Colors.green),
          );
        }
      },
    );
  }

  Future<void> _presentIAPManagement(BuildContext context, IAPService? iapService) async {
    if (iapService == null) {
      _showError(context, 'IAP service not available');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Subscription'),
        content: const Text('You can restore purchases or manage your subscription through your device\'s app store.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _restorePurchases(context, iapService);
            },
            child: const Text('Restore Purchases'),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases(BuildContext context, IAPService? iapService) async {
    if (iapService == null) {
      _showError(context, 'IAP service not available');
      return;
    }
    try {
      await iapService.restorePurchases();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore request sent')));
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Failed to restore purchases: $e');
    }
  }

  Widget _buildVerificationWarning(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Please verify your email to access Pro features.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                try {
                  final authService = context.read<AuthService>();
                  await authService.resendVerificationEmail();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showError(context, 'Error: $e');
                  }
                }
              },
              child: const Text('Resend Verification Email'),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
