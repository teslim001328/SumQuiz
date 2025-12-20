import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../services/referral_service.dart';

/// A completely redesigned screen for the referral program.
///
/// This screen provides a modern, interactive, and informative UI for the user
/// to engage with the referral system. It displays their unique referral code,
/// allows for easy copying and sharing, and shows real-time statistics on their
/// referral performance.
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late Future<String> _referralCodeFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the referral code when the screen initializes.
    // This is a one-time fetch, ideal for data that doesn't change during the screen's lifecycle.
    final authService = Provider.of<AuthService>(context, listen: false);
    final referralService =
        Provider.of<ReferralService>(context, listen: false);
    _referralCodeFuture =
        referralService.generateReferralCode(authService.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final referralService = Provider.of<ReferralService>(context);
    final authService = Provider.of<AuthService>(context);
    final uid = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer a Friend'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Text(
              'Invite Friends, Get Rewards!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your unique code with friends. When they sign up, they get 7 free Pro days, and you earn rewards after just 2 referrals!',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 32),

            // --- Referral Code Card ---
            _buildReferralCodeCard(theme, _referralCodeFuture),

            const SizedBox(height: 40),

            // --- Stats Section ---
            Text(
              'Your Progress',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(theme, referralService, uid),

            const SizedBox(height: 40),

            // --- How It Works Section ---
            _buildHowItWorks(theme),
          ],
        ),
      ),
    );
  }

  /// Builds the interactive card displaying the user's referral code.
  Widget _buildReferralCodeCard(ThemeData theme, Future<String> codeFuture) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'YOUR UNIQUE CODE',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: codeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Text('Could not load code');
              }
              final code = snapshot.data!;
              return InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Referral code copied to clipboard!')),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        code,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.copy_all_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final code = await _referralCodeFuture;
              Share.share(
                  'Join me on SumQuiz and get 7 free Pro days! Use my code: $code\n\nDownload the app here: [App Store Link]',
                  subject: 'Get Free Pro Days on SumQuiz!');
            },
          ),
        ],
      ),
    );
  }

  /// Builds the grid displaying real-time referral statistics.
  Widget _buildStatsGrid(
      ThemeData theme, ReferralService referralService, String uid) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(theme, 'Pending', referralService.getReferralCount(uid),
            Icons.people_outline_rounded),
        _buildStatCard(
            theme,
            'Total Friends',
            referralService.getTotalReferralCount(uid),
            Icons.group_add_rounded),
        _buildStatCard(
            theme,
            'Rewards Earned',
            referralService.getReferralRewards(uid),
            Icons.card_giftcard_rounded),
      ],
    );
  }

  /// Builds a single card for a statistic.
  Widget _buildStatCard(
      ThemeData theme, String label, Stream<int> stream, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final value = snapshot.data ?? 0;
              return Text(
                value.toString(),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Builds the section explaining how the referral process works.
  Widget _buildHowItWorks(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStep(theme, Icons.one_k, 'Share Your Code',
            'Send your unique code to friends via text, email, or social media.'),
        _buildStep(theme, Icons.two_k, 'Friend Signs Up',
            'Your friend enters your code during signup and instantly receives 7 Pro days.'),
        _buildStep(theme, Icons.three_k, 'You Get Rewarded',
            'After 2 friends sign up, you earn a reward: 7 extra days of Pro subscription!'),
      ],
    );
  }

  /// Builds a single step in the 'How It Works' section.
  Widget _buildStep(
      ThemeData theme, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
