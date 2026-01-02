import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/services/auth_service.dart';
import 'package:sumquiz/services/referral_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final authService = Provider.of<AuthService>(context, listen: false);
    final referralService =
        Provider.of<ReferralService>(context, listen: false);
    _referralCodeFuture =
        referralService.generateReferralCode(authService.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    final referralService = Provider.of<ReferralService>(context);
    final authService = Provider.of<AuthService>(context);
    final uid = authService.currentUser!.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Refer a Friend',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Animated Background
          Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              CustomEffect(
                duration: 10.seconds,
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0F2027), // Dark slate
                          Color.lerp(const Color(0xFF203A43),
                              const Color(0xFF2C5364), value)!, // Tealish dark
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.volunteer_activism,
                                    size: 80, color: Colors.white)
                                .animate()
                                .scale()
                                .fadeIn(),
                            const SizedBox(height: 16),
                            Text(
                              'Invite Friends, Get Rewards!',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate()
                                .fadeIn(delay: 100.ms)
                                .slideY(begin: 0.1),
                            const SizedBox(height: 12),
                            Text(
                              'Give 7 days of Pro, Get 7 days of Pro!',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent,
                                  fontSize: 16),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 8),
                            Text(
                              'Share your unique code. When friends sign up, they get 7 free Pro days. You earn 7 days for every 2 friends who join!',
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 14),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 300.ms),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildReferralCodeCard(_referralCodeFuture)
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .shimmer(delay: 1000.ms),
                      const SizedBox(height: 40),
                      Text(
                        'Your Progress',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 16),
                      _buildStatsGrid(referralService, uid)
                          .animate()
                          .fadeIn(delay: 600.ms),
                      const SizedBox(height: 40),
                      _buildHowItWorks().animate().fadeIn(delay: 700.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer(
      {required Widget child, EdgeInsets padding = const EdgeInsets.all(24)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(Future<String> codeFuture) {
    return _buildGlassContainer(
      child: Column(
        children: [
          Text(
            'YOUR UNIQUE CODE',
            style: GoogleFonts.inter(
                color: Colors.blueAccent.shade100,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12),
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: codeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(color: Colors.white);
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return Text('Could not load code',
                    style: GoogleFonts.inter(color: Colors.white54));
              }
              final code = snapshot.data!;
              return InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Referral code copied to clipboard!'),
                        backgroundColor: Colors.green),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        code,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.copy_all_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              label: Text('Share Code',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () async {
                final code = await _referralCodeFuture;
                Share.share(
                    'Join me on SumQuiz and get 7 free Pro days! Use my code: $code\n\nDownload the app here: [App Store Link]',
                    subject: 'Get Free Pro Days on SumQuiz!');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ReferralService referralService, String uid) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildStatCard('Pending', referralService.getReferralCount(uid),
            Icons.hourglass_empty_rounded),
        _buildStatCard(
            'Total Friends',
            referralService.getTotalReferralCount(uid),
            Icons.group_add_rounded),
        _buildStatCard(
            'Rewards Earned',
            referralService.getReferralRewards(uid),
            Icons.card_giftcard_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, Stream<int> stream, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.amberAccent),
          const SizedBox(height: 12),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final value = snapshot.data ?? 0;
              return Text(
                value.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildGlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStep(Icons.looks_one_rounded, 'Share Your Code',
                  'Send your unique code to friends via text, email, or social media.'),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              _buildStep(Icons.looks_two_rounded, 'Friend Signs Up',
                  'Your friend enters your code during signup and instantly receives 7 Pro days.'),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              _buildStep(Icons.looks_3_rounded, 'You Get Rewarded',
                  'After 2 friends sign up, you earn a reward: 7 extra days of Pro subscription!'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent.shade100, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(description,
                    style:
                        GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
