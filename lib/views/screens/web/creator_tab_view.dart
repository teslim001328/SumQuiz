import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/theme/web_theme.dart';

class CreatorTabView extends StatelessWidget {
  const CreatorTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(context),
          _buildVisualStats(context),
          _buildProcessSection(context),
          _buildFeaturesSection(context),
          _buildTestimonials(context),
          _buildFAQ(context),
          _buildCTASection(context),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebColors.background,
            WebColors.primary.withOpacity(0.05),
            const Color(0xFFF3E8FF), // Light purple for creator vibe
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              // Left Content
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: WebColors.primary.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on,
                              color: WebColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Earn 70% Revenue Share',
                            style: TextStyle(
                              color: WebColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                      ).createShader(bounds),
                      child: Text(
                        'Monetize Your Knowledge',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -1,
                          color: Colors.white,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 24),
                    Text(
                      'Create once, earn forever. Transform your expertise into interactive study decks and reach thousands of students globally.',
                      style: TextStyle(
                        fontSize: 20,
                        color: WebColors.textSecondary,
                        height: 1.6,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 48),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildPrimaryButton(context, 'Start Creating Now',
                            () => context.go('/create')),
                        _buildSecondaryButton(context, 'View Dashboard',
                            () => context.go('/dashboard')),
                      ],
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        _buildTrustBadge(Icons.auto_graph, 'Passive Income'),
                        _buildTrustBadge(Icons.public, 'Global Reach'),
                        _buildTrustBadge(Icons.shield, 'Secure Payouts'),
                      ],
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              // Right Image
              Expanded(
                flex: 1,
                child: Container(
                  height: 500,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: WebColors.primary.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/web/creator_hero.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      color: Colors.white,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('70%', 'Revenue Share', Icons.pie_chart),
              _buildDivider(),
              _buildStatItem(
                  '\$2.5k+', 'Avg. Creator Earnings', Icons.payments),
              _buildDivider(),
              _buildStatItem('500+', 'Active Creators', Icons.people),
              _buildDivider(),
              _buildStatItem('24h', 'Payout Processing', Icons.timer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      color: WebColors.border,
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: WebColors.primary, size: 32),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: WebColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: WebColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: WebColors.backgroundAlt,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildSectionTitle(
                  'How It Works', 'Start earning in 3 simple steps'),
              const SizedBox(height: 60),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProcessStep(
                    1,
                    'Create & Verify',
                    'Use our AI tools to generate high-quality quizzes and summaries. Get verified as a creator.',
                    Icons.verified_user,
                  ),
                  _buildProcessStep(
                    2,
                    'Publish Content',
                    'Set your decks to "Public Premium" or "Public Free" to reach students worldwide.',
                    Icons.publish,
                  ),
                  _buildProcessStep(
                    3,
                    'Earn Revenue',
                    'Get paid every time a Pro user studies your content. Track earnings in real-time.',
                    Icons.attach_money,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessStep(
      int number, String title, String description, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [WebColors.primary, const Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: WebColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: WebColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: WebColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildSectionTitle(
                  'Creator Tools', 'Everything you need to succeed'),
              const SizedBox(height: 60),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _buildFeatureCard(
                    Icons.analytics,
                    'Advanced Analytics',
                    'Track views, completion rates, and student engagement in real-time.',
                    Colors.blue,
                  ),
                  _buildFeatureCard(
                    Icons.auto_awesome,
                    'AI Content Assist',
                    'Generate comprehensive metadata and tags to boost discoverability.',
                    Colors.purple,
                  ),
                  _buildFeatureCard(
                    Icons.copyright,
                    'Content Protection',
                    'Your content is encrypted and protected against unauthorized copying.',
                    Colors.indigo,
                  ),
                  _buildFeatureCard(
                    Icons.groups,
                    'Community Building',
                    'Build a following. Students can subscribe to your profile for updates.',
                    Colors.orange,
                  ),
                  _buildFeatureCard(
                    Icons.edit_document,
                    'Rich Editor',
                    'Full markdown support, image uploads, and mathematical equations.',
                    Colors.teal,
                  ),
                  _buildFeatureCard(
                    Icons.campaign,
                    'Promotion Tools',
                    'Generate social sharing cards and embed codes for your blog.',
                    Colors.pink,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      IconData icon, String title, String desc, Color color) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(
              fontSize: 15,
              color: WebColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate(effects: [const FadeEffect(), const ScaleEffect()]);
  }

  Widget _buildTestimonials(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: WebColors.backgroundAlt,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildSectionTitle(
                  'Creator Stories', 'Join successful educators'),
              const SizedBox(height: 60),
              Row(
                children: [
                  Expanded(
                      child: _buildTestimonialCard(
                    'Prof. David Miller',
                    'Biology Professor',
                    'I use SumQuiz to publish my lecture supplements. The passive income now covers my car payments!',
                    'assets/images/web/testimonial_avatar_1.png',
                  )),
                  Expanded(
                      child: _buildTestimonialCard(
                    'Sarah Jenkins',
                    'Medical Student',
                    'Sharing my USMLE prep decks has helped thousands of students and paid for my textbooks.',
                    'assets/images/web/testimonial_avatar_2.png',
                  )),
                  Expanded(
                      child: _buildTestimonialCard(
                    'TechBootcamp',
                    'Coding School',
                    'We publish our curriculum reviews here. It\'s a great lead magnet for our full courses.',
                    'assets/images/web/testimonial_avatar_3.png',
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(
      String name, String role, String text, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
                5,
                (index) =>
                    const Icon(Icons.star, color: Colors.amber, size: 20)),
          ),
          const SizedBox(height: 20),
          Text(
            '"$text"',
            style: TextStyle(
              fontSize: 16,
              color: WebColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(imagePath),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: WebColors.textPrimary,
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 13,
                      color: WebColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildSectionTitle(
                  'Creator FAQ', 'Common questions about earning'),
              const SizedBox(height: 60),
              _buildFAQItem('How do payouts work?',
                  'Payouts are processed monthly via Stripe or PayPal once you reach the \$50 minimum threshold. You keep 70% of net revenue generated by valid views.'),
              _buildFAQItem('Do I lose rights to my content?',
                  'No. You retain full ownership of your content. You grant SumQuiz a non-exclusive license to display and monetize it.'),
              _buildFAQItem('Can I offer free content?',
                  'Yes! You can choose to make decks "Public Free" to build an audience, or "Public Premium" to earn revenue.'),
              _buildFAQItem('What kind of content can I sell?',
                  'Any educational content: university notes, language decks, certification prep, coding quizzes, etc. Must be original.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            q,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: WebColors.textPrimary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                a,
                style: TextStyle(
                  fontSize: 15,
                  color: WebColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Text(
              'Ready to Monetize Your Knowledge?',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Join 500+ creators earning passive income today.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => context.go('/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: WebColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Creating for Free',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    // Reusing standard footer style but simplified for this tab
    // Ideally this should be a shared widget, but for now we duplicate the visual
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              WebColors.primary,
                              const Color(0xFF8B5CF6)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'SumQuiz',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '© 2024 SumQuiz Inc. All rights reserved.',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String badge, String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: WebColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge.toUpperCase(),
            style: TextStyle(
              color: WebColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: WebColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [WebColors.primary, const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: WebColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: WebColors.textPrimary,
        side: BorderSide(color: WebColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          Icon(icon, color: WebColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: WebColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
