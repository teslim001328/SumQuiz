import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/iap_service.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedProductId;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final iapService = context.watch<IAPService?>();
    final authUser = context.watch<AuthService>().currentUser;
    final isVerified = authUser?.emailVerified ?? false;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('SumQuiz Pro',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on, color: theme.colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              if (authUser != null && !isVerified)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildVerificationWarning(context),
                ),
              Expanded(
                child: FutureBuilder<bool>(
                  future: _checkProStatus(iapService),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final hasPro = snapshot.data ?? user?.isPro ?? false;

                    if (hasPro) {
                      return _buildProMemberView(context, iapService);
                    }

                    return _buildUpgradeView(context, iapService);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _checkProStatus(IAPService? service) async {
    return await service?.hasProAccess() ?? false;
  }

  Widget _buildUpgradeView(BuildContext context, IAPService? iapService) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Learn faster. Remember smarter.',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Features',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureListItem(theme, 'Unlimited quizzes', true),
          _buildFeatureListItem(theme, 'Advanced analytics', false),
          _buildFeatureListItem(theme, 'Personalized learning', false),
          _buildFeatureListItem(theme, 'Offline access', false),
          _buildFeatureListItem(theme, 'Ad-free experience', false),
          const SizedBox(height: 32),
          FutureBuilder<List<ProductDetails>?>(
            future: iapService?.getAvailableProducts() ?? Future.value([]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Subscription plans not available.'));
              }

              final products = snapshot.data!;
              final monthly = products.firstWhere(
                  (p) => p.id.contains('monthly'),
                  orElse: () => products.first);
              final annual = products.firstWhere((p) => p.id.contains('annual'),
                  orElse: () => products.first);
              final lifetime = products.firstWhere(
                  (p) => p.id.contains('lifetime'),
                  orElse: () => products.first);

              _selectedProductId ??= annual.id;

              return Column(
                children: [
                  _buildSubscriptionCard(
                    context: context,
                    product: monthly,
                    title: 'Monthly',
                    subtitle: '/month',
                    billingInfo: 'Billed monthly',
                    isSelected: _selectedProductId == monthly.id,
                    onTap: () =>
                        setState(() => _selectedProductId = monthly.id),
                  ),
                  const SizedBox(height: 16),
                  _buildSubscriptionCard(
                    context: context,
                    product: annual,
                    title: 'Annual',
                    subtitle: '/year',
                    billingInfo: 'Billed annually',
                    badgeText: 'Best Value',
                    isSelected: _selectedProductId == annual.id,
                    onTap: () => setState(() => _selectedProductId = annual.id),
                  ),
                  const SizedBox(height: 16),
                  _buildSubscriptionCard(
                    context: context,
                    product: lifetime,
                    title: 'Lifetime',
                    subtitle: '',
                    billingInfo: 'One-time purchase',
                    isSelected: _selectedProductId == lifetime.id,
                    onTap: () =>
                        setState(() => _selectedProductId = lifetime.id),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedProductId != null && iapService != null) {
                  final products = await iapService.getAvailableProducts();
                  final selectedProduct =
                      products.firstWhere((p) => p.id == _selectedProductId);
                  await iapService.purchaseProduct(selectedProduct.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0000FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upgrade to Pro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: const [
                  TextSpan(
                      text: 'Invite 3 friends and get 1 week of Pro free '),
                  WidgetSpan(
                    child: Text('🎁', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required BuildContext context,
    required ProductDetails product,
    required String title,
    required String subtitle,
    required String billingInfo,
    required bool isSelected,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color:
                    isSelected ? const Color(0xFF0000FF) : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(product.price,
                          style: theme.textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(subtitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.check, size: 20, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(billingInfo, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (badgeText != null)
            Positioned(
              top: -15,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0000FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      badgeText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.diamond, color: Colors.white, size: 12),
                  ],
                ),
              ),
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
        children: [
          const Icon(Icons.verified, size: 80, color: Colors.amber),
          const SizedBox(height: 24),
          Text('You\'re a Pro Member!',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Enjoy unlimited access to all features',
              style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: theme.dividerColor.withAlpha(25))),
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pro Benefits',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildFeatureItem(theme, 'Unlimited content generation'),
                  _buildFeatureItem(theme, 'Unlimited folders'),
                  _buildFeatureItem(theme, 'Unlimited Flashcards'),
                  _buildFeatureItem(theme, 'Offline Access'),
                  _buildFeatureItem(theme, 'Full Spaced Repetition System'),
                  _buildFeatureItem(theme, 'Progress analytics with exports'),
                  _buildFeatureItem(theme, 'Daily missions with full rewards'),
                  _buildFeatureItem(theme, 'All gamification rewards'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _presentIAPManagement(context, iapService),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Manage Subscription'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildFeatureListItem(ThemeData theme, String text, bool isUnlocked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          isUnlocked
              ? const Icon(Icons.check_box, size: 22, color: Color(0xFF34C759))
              : const Icon(Icons.lock, size: 22, color: Colors.amber),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _presentIAPManagement(
      BuildContext context, IAPService? iapService) async {
    if (iapService == null) {
      _showError(context, 'IAP service not available');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Subscription'),
        content: const Text(
            'You can restore purchases or manage your subscription through your device\'s app store.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
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

  Future<void> _restorePurchases(
      BuildContext context, IAPService? iapService) async {
    if (iapService == null) {
      _showError(context, 'IAP service not available');
      return;
    }
    try {
      await iapService.restorePurchases();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restore request sent')));
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to restore purchases: $e');
      }
    }
  }

  Widget _buildVerificationWarning(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withAlpha(128)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please verify your email to purchase subscriptions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
