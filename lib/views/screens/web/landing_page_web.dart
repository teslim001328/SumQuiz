import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/theme/web_theme.dart';
import 'package:sumquiz/views/screens/web/creator_tab_view.dart';

class LandingPageWeb extends StatefulWidget {
  const LandingPageWeb({super.key});

  @override
  State<LandingPageWeb> createState() => _LandingPageWebState();
}

class _LandingPageWebState extends State<LandingPageWeb>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebColors.background,
      body: Column(
        children: [
          _buildNavBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Student Tab
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      _buildHeroSection(context),
                      _buildStatsSection(context),
                      _buildFeaturesGrid(context),
                      _buildHowItWorks(context),
                      _buildCTASection(context),
                      _buildFooter(context),
                    ],
                  ),
                ),
                // Creator Tab
                const CreatorTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: WebColors.border, width: 1),
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Icon(Icons.school, color: WebColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'SumQuiz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: WebColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Tab switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: WebColors.backgroundAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: WebColors.subtleShadow,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: WebColors.textPrimary,
                  unselectedLabelColor: WebColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'For Students'),
                    Tab(text: 'For Creators'),
                  ],
                ),
              ),
              // Auth buttons
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Log In'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              // Left side - Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: WebColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'AI-Powered Study Platform',
                        style: TextStyle(
                          color: WebColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),
                    // Hero title
                    Text(
                      'Study Smarter,\nNot Harder',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: WebColors.textPrimary,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 20),
                    // Subtitle
                    Text(
                      'Transform your study materials into summaries, quizzes, and flashcards with AI. Save hours and ace your exams.',
                      style: TextStyle(
                        fontSize: 20,
                        color: WebColors.textSecondary,
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 40),
                    // CTA buttons
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/auth'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                          ),
                          child: const Text('Get Started Free'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                          ),
                          child: const Text('See How It Works'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 32),
                    // Trust badges
                    Row(
                      children: [
                        _buildTrustBadge(Icons.verified_user, '100% Secure'),
                        const SizedBox(width: 24),
                        _buildTrustBadge(Icons.flash_on, 'Instant Results'),
                        const SizedBox(width: 24),
                        _buildTrustBadge(Icons.people, '500+ Students'),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              // Right side - Screenshot placeholder
              Expanded(
                child: Container(
                  height: 500,
                  decoration: BoxDecoration(
                    color: WebColors.backgroundAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WebColors.border),
                    boxShadow: WebColors.cardShadow,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dashboard,
                          size: 64,
                          color: WebColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Product Screenshot',
                          style: TextStyle(
                            color: WebColors.textTertiary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: WebColors.secondary, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: WebColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      color: WebColors.backgroundAlt,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('500+', 'Active Students'),
              _buildStatItem('10K+', 'Study Materials'),
              _buildStatItem('50hrs', 'Time Saved'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: WebColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: WebColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      {
        'icon': Icons.bolt,
        'title': 'Lightning Fast',
        'desc': 'Generate comprehensive study materials from PDFs in seconds.',
      },
      {
        'icon': Icons.psychology,
        'title': 'Exam-Focused AI',
        'desc': 'AI trained on exam patterns to create test-ready questions.',
      },
      {
        'icon': Icons.school,
        'title': 'Smart Flashcards',
        'desc': 'Spaced repetition ensures you remember what matters most.',
      },
      {
        'icon': Icons.video_library,
        'title': 'YouTube Analysis',
        'desc': 'Extract key concepts from educational videos with AI.',
      },
      {
        'icon': Icons.analytics,
        'title': 'Progress Tracking',
        'desc': 'Visualize your learning journey with detailed analytics.',
      },
      {
        'icon': Icons.cloud_sync,
        'title': 'Cloud Sync',
        'desc': 'Access your study materials anywhere, anytime.',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Everything You Need to Succeed',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Powerful features to help you ace your exams',
                style: TextStyle(
                  fontSize: 20,
                  color: WebColors.textSecondary,
                ),
              ),
              const SizedBox(height: 60),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.2,
                ),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _buildFeatureCard(
                    icon: feature['icon'] as IconData,
                    title: feature['title'] as String,
                    description: feature['desc'] as String,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WebColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: WebColors.primary, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: WebColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: WebColors.backgroundAlt,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'How It Works',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 60),
              _buildStep(
                number: '1',
                title: 'Upload Your Content',
                description:
                    'Upload PDFs, paste text, or share a YouTube link.',
                icon: Icons.upload_file,
              ),
              const SizedBox(height: 40),
              _buildStep(
                number: '2',
                title: 'AI Generates Materials',
                description:
                    'Our AI creates summaries, quizzes, and flashcards instantly.',
                icon: Icons.auto_awesome,
              ),
              const SizedBox(height: 40),
              _buildStep(
                number: '3',
                title: 'Study and Track Progress',
                description:
                    'Review your materials and track your learning progress.',
                icon: Icons.trending_up,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: WebColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: WebColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        Icon(icon, size: 48, color: WebColors.textTertiary),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(60),
          decoration: BoxDecoration(
            color: WebColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Ready to Transform Your Study Routine?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Join hundreds of students who are already studying smarter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.go('/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: WebColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                ),
                child: const Text('Get Started Free'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      color: WebColors.backgroundAlt,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school,
                                color: WebColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'SumQuiz',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: WebColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI-powered study platform for students',
                          style: TextStyle(
                            color: WebColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFooterColumn('Product', [
                    'Features',
                    'Pricing',
                    'FAQ',
                  ]),
                  _buildFooterColumn('Company', [
                    'About',
                    'Blog',
                    'Contact',
                  ]),
                  _buildFooterColumn('Legal', [
                    'Privacy',
                    'Terms',
                    'Security',
                  ]),
                ],
              ),
              const SizedBox(height: 40),
              Divider(color: WebColors.border),
              const SizedBox(height: 20),
              Text(
                '© 2026 SumQuiz. All rights reserved.',
                style: TextStyle(
                  color: WebColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> links) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                link,
                style: TextStyle(
                  color: WebColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
