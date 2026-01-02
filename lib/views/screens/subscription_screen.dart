import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('SumQuiz Pro',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A3420))), // Dark Brown/Gold
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF4A3420)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Premium Gold/Amber Gradient Background
          Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              CustomEffect(
                duration: 6.seconds,
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFFF8E1), // Pale Amber
                          Color.lerp(const Color(0xFFFFECB3),
                              const Color(0xFFFFE082), value)!,
                        ],
                      ),
                    ),
                    child: child,
                  );
                },
              )
            ],
            child: Container(),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    if (authUser != null && !isVerified)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildVerificationWarning(context),
                      ).animate().fadeIn().slideY(begin: -0.5),
                    Expanded(
                      child: FutureBuilder<bool>(
                        future: _checkProStatus(iapService),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
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
          ),
        ],
      ),
    );
  }

  Future<bool> _checkProStatus(IAPService? service) async {
    return await service?.hasProAccess() ?? false;
  }

  Widget _buildUpgradeView(BuildContext context, IAPService? iapService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Animated Pro Badge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                size: 80, color: Color(0xFFFFA000)), // Amber 700
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.1, duration: 2.seconds),

          const SizedBox(height: 32),
          Text(
            'Unlock SumQuiz Pro',
            style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A3420)),
            textAlign: TextAlign.center,
          ).animate().fadeIn().slideY(begin: 0.2),

          const SizedBox(height: 12),
          Text('Master your learning with unlimited access.',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF6D4C41)), // Brown 600
                  textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 200.ms),

          const SizedBox(height: 48),

          _buildGlassContainer(
            padding: const EdgeInsets.all(24),
            child: _buildFeatureList(context),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _showIAPProducts(context, iapService),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000), // Amber 700
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: Colors.amber.withValues(alpha: 0.5),
              ),
              child: Text('Get Pro Access',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _restorePurchases(context, iapService),
            child: Text('Restore Purchases',
                style: GoogleFonts.inter(
                    color: const Color(0xFF6D4C41),
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProMemberView(BuildContext context, IAPService? iapService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.verified_rounded, size: 100, color: Colors.green)
              .animate()
              .scale(curve: Curves.elasticOut, duration: 800.ms),
          const SizedBox(height: 24),
          Text('You are a Pro Member!',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A3420))),
          const SizedBox(height: 12),
          Text('Thank you for supporting SumQuiz.',
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF6D4C41)),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          _buildGlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Text('Your Pro Benefits',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4A3420))),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(context, 'Unlimited AI Generation'),
                _buildFeatureItem(context, 'Unlimited Folders & Decks'),
                _buildFeatureItem(context, 'Cloud Sync & Offline Mode'),
                _buildFeatureItem(context, 'Advanced Analytics'),
                _buildFeatureItem(context, 'Priority Support'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _presentIAPManagement(context, iapService),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6D4C41), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Manage Subscription',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6D4C41))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8D6E63)
                    .withValues(alpha: 0.1), // Brownish shadow
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    return Column(
      children: [
        _buildFeatureItem(context, 'Unlimited content generation'),
        _buildFeatureItem(context, 'Unlimited folders & decks'),
        _buildFeatureItem(context, 'Smart Spaced Repetition'),
        _buildFeatureItem(context, 'Offline access & Sync'),
        _buildFeatureItem(context, 'Detailed progress analytics'),
        _buildFeatureItem(context, 'Daily missions & rewards'),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child:
                const Icon(Icons.check_rounded, size: 18, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(
                      fontSize: 15, color: const Color(0xFF3E2723)))),
        ],
      ),
    );
  }

  Future<void> _showIAPProducts(
      BuildContext context, IAPService? iapService) async {
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

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent, // Important for glass effect
        builder: (context) => _buildGlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text('Choose a Plan',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A3420))),
              const SizedBox(height: 24),
              ...products.map((p) => _buildProductTile(context, p, iapService)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) _showError(context, 'Failed to load products: $e');
    }
  }

  Widget _buildProductTile(
      BuildContext context, ProductDetails product, IAPService iapService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(product.title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFF4A3420))),
        subtitle: Text(product.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: const Color(0xFF6D4C41))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFFFA000),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]),
          child: Text(product.price,
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        onTap: () async {
          Navigator.of(context).pop();
          final success = await iapService.purchaseProduct(product.id);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Welcome to SumQuiz Pro! 🎉'),
                  backgroundColor: Colors.green),
            );
          }
        },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Manage Subscription',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
            'You can restore purchases or manage your subscription through your device\'s app store.',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  Text('Close', style: GoogleFonts.inter(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _restorePurchases(context, iapService);
            },
            child: Text('Restore Purchases',
                style: GoogleFonts.inter(
                    color: const Color(0xFFFFA000),
                    fontWeight: FontWeight.bold)),
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
    return _buildGlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Please verify your email to access Pro features.',
                    style: GoogleFonts.inter(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Verification email sent!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showError(context, 'Error: $e');
                  }
                }
              },
              child: Text('Resend Verification Email',
                  style: GoogleFonts.inter(color: Colors.redAccent)),
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
