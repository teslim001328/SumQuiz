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
                      _buildSocialProof(context),
                      _buildStatsSection(context),
                      _buildFeaturesGrid(context),
                      _buildHowItWorks(context),
                      _buildTestimonials(context),
                      _buildPricing(context),
                      _buildFAQ(context),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [WebColors.primary, const Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: WebColors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: WebColors.primary,
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
                    style: TextButton.styleFrom(
                      foregroundColor: WebColors.textSecondary,
                    ),
                    child: const Text('Log In'),
                  ),
                  const SizedBox(width: 12),
                  Container(
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
                      onPressed: () => context.go('/auth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Get Started Free'),
                    ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFEEF2FF),
            const Color(0xFFF3E8FF),
          ],
        ),
      ),
      child: Container(
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
                          gradient: LinearGradient(
                            colors: [
                              WebColors.primary.withOpacity(0.1),
                              const Color(0xFF8B5CF6).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: WebColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: WebColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'AI-Powered Study Platform',
                              style: TextStyle(
                                color: WebColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                      const SizedBox(height: 24),
                      // Hero title
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            WebColors.textPrimary,
                            const Color(0xFF6366F1)
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Study Smarter,\nNot Harder',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 24),
                      // Subtitle
                      Text(
                        'Transform your study materials into summaries, quizzes, and flashcards with AI. Save hours every week and ace your exams with confidence.',
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
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  WebColors.primary,
                                  const Color(0xFF8B5CF6)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: WebColors.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/auth'),
                              icon: const Icon(Icons.rocket_launch, size: 20),
                              label: const Text('Get Started Free'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 20,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Watch Demo'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                              side:
                                  BorderSide(color: WebColors.border, width: 2),
                              foregroundColor: WebColors.textPrimary,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 40),
                      // Trust badges
                      Row(
                        children: [
                          _buildTrustBadge(
                              Icons.verified_user, 'Secure & Private'),
                          const SizedBox(width: 32),
                          _buildTrustBadge(Icons.bolt, 'Instant Results'),
                          const SizedBox(width: 32),
                          _buildTrustBadge(Icons.star, '4.9★ Rating'),
                        ],
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                // Right side - Hero Image
                Expanded(
                  child: Container(
                    height: 520,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: WebColors.primary.withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/web/hero_illustration.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.8)),
                                const SizedBox(height: 16),
                                Text(
                                  'AI-Powered Learning',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: WebColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: WebColors.secondary, size: 18),
        ),
        const SizedBox(width: 10),
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

  Widget _buildSocialProof(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Text(
              'TRUSTED BY STUDENTS AT',
              style: TextStyle(
                color: WebColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoPlaceholder('Stanford'),
                const SizedBox(width: 48),
                _buildLogoPlaceholder('MIT'),
                const SizedBox(width: 48),
                _buildLogoPlaceholder('Harvard'),
                const SizedBox(width: 48),
                _buildLogoPlaceholder('Oxford'),
                const SizedBox(width: 48),
                _buildLogoPlaceholder('Berkeley'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(String name) {
    return Text(
      name,
      style: TextStyle(
        color: WebColors.textTertiary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [WebColors.primary, const Color(0xFF8B5CF6)],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('10K+', 'Study Materials Created', Icons.article),
              _buildStatItem('500+', 'Active Students', Icons.people),
              _buildStatItem('50hrs', 'Saved Weekly', Icons.schedule),
              _buildStatItem('4.9★', 'Average Rating', Icons.star),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 32),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      {
        'icon': Icons.bolt,
        'color': const Color(0xFFF59E0B),
        'title': 'Lightning Fast',
        'desc':
            'Generate comprehensive study materials from any PDF, video, or text in seconds.',
      },
      {
        'icon': Icons.psychology,
        'color': const Color(0xFF8B5CF6),
        'title': 'Exam-Focused AI',
        'desc':
            'AI trained on exam patterns to create test-ready questions that match your syllabus.',
      },
      {
        'icon': Icons.style,
        'color': const Color(0xFF10B981),
        'title': 'Smart Flashcards',
        'desc':
            'Spaced repetition algorithm ensures you remember what matters most, longer.',
      },
      {
        'icon': Icons.play_circle_filled,
        'color': const Color(0xFFEF4444),
        'title': 'YouTube Analysis',
        'desc':
            'Extract key concepts from educational videos automatically with AI.',
      },
      {
        'icon': Icons.insights,
        'color': const Color(0xFF3B82F6),
        'title': 'Progress Analytics',
        'desc':
            'Visualize your learning journey with detailed performance insights.',
      },
      {
        'icon': Icons.cloud_sync,
        'color': const Color(0xFF6366F1),
        'title': 'Cloud Sync',
        'desc': 'Access your study materials anywhere, anytime, on any device.',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: WebColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'FEATURES',
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
                'Everything You Need to Succeed',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Powerful AI-driven features designed to maximize your study efficiency',
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
                  childAspectRatio: 1.1,
                ),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _buildFeatureCard(
                    icon: feature['icon'] as IconData,
                    color: feature['color'] as Color,
                    title: feature['title'] as String,
                    description: feature['desc'] as String,
                  )
                      .animate(delay: Duration(milliseconds: 100 * index))
                      .fadeIn()
                      .slideY(begin: 0.2);
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
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 24),
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
              fontSize: 15,
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
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: WebColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'HOW IT WORKS',
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
                'Start Learning in 3 Simple Steps',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 60),
              _buildStep(
                number: '1',
                title: 'Upload Your Content',
                description:
                    'Upload PDFs, paste text, or share a YouTube link. We support multiple formats.',
                icon: Icons.cloud_upload,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 40),
              _buildStep(
                number: '2',
                title: 'AI Generates Materials',
                description:
                    'Our advanced AI creates personalized summaries, quizzes, and flashcards instantly.',
                icon: Icons.auto_awesome,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 40),
              _buildStep(
                number: '3',
                title: 'Study & Track Progress',
                description:
                    'Review your materials with spaced repetition and track your learning analytics.',
                icon: Icons.trending_up,
                color: const Color(0xFF10B981),
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
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials(BuildContext context) {
    final testimonials = [
      {
        'avatar': 'assets/images/web/avatar_1.png',
        'name': 'Sarah Chen',
        'role': 'Pre-Med Student, Stanford',
        'text':
            'SumQuiz saved me 10+ hours per week on MCAT prep. The AI-generated quizzes are incredibly accurate and helped me identify weak areas instantly.',
      },
      {
        'avatar': 'assets/images/web/avatar_2.png',
        'name': 'Marcus Johnson',
        'role': 'Graduate Student, MIT',
        'text':
            'Finally an AI tool that actually understands academic content. The flashcards adapt to my learning pace and the analytics keep me motivated.',
      },
      {
        'avatar': 'assets/images/web/avatar_3.png',
        'name': 'Maria Rodriguez',
        'role': 'Law Student, UCLA',
        'text':
            'I was skeptical at first, but the quality of summaries is remarkable. It\'s like having a personal study assistant available 24/7.',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: WebColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'TESTIMONIALS',
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
                'Loved by Students Worldwide',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 60),
              Row(
                children: testimonials.asMap().entries.map((entry) {
                  final testimonial = entry.value;
                  return Expanded(
                    child: _buildTestimonialCard(
                      avatar: testimonial['avatar'] as String,
                      name: testimonial['name'] as String,
                      role: testimonial['role'] as String,
                      text: testimonial['text'] as String,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialCard({
    required String avatar,
    required String name,
    required String role,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
                5,
                (i) =>
                    Icon(Icons.star, color: const Color(0xFFF59E0B), size: 20)),
          ),
          const SizedBox(height: 20),
          Text(
            '"$text"',
            style: TextStyle(
              fontSize: 16,
              color: WebColors.textSecondary,
              height: 1.8,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  avatar,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: WebColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: WebColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: WebColors.textPrimary,
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildPricing(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: WebColors.backgroundAlt,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: WebColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PRICING',
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
                'Simple, Transparent Pricing',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Start free and upgrade when you\'re ready',
                style: TextStyle(
                  fontSize: 20,
                  color: WebColors.textSecondary,
                ),
              ),
              const SizedBox(height: 60),
              Row(
                children: [
                  Expanded(
                      child: _buildPricingCard(
                    title: 'Free',
                    price: '\$0',
                    period: '/month',
                    description: 'Perfect for getting started',
                    features: [
                      '5 uploads per week',
                      'Basic AI generation',
                      'Cloud sync',
                      'Basic analytics',
                    ],
                    buttonText: 'Get Started',
                    isPopular: false,
                  )),
                  Expanded(
                      child: _buildPricingCard(
                    title: 'Pro',
                    price: '\$9.99',
                    period: '/month',
                    description: 'For serious students',
                    features: [
                      'Unlimited uploads',
                      'Advanced AI generation',
                      'Priority processing',
                      'Advanced analytics',
                      'Export to PDF/Anki',
                      'Priority support',
                    ],
                    buttonText: 'Upgrade to Pro',
                    isPopular: true,
                  )),
                  Expanded(
                      child: _buildPricingCard(
                    title: 'Creator',
                    price: 'Free Pro',
                    period: '',
                    description: 'Share & earn forever',
                    features: [
                      'All Pro features',
                      'Publish public decks',
                      'Creator analytics',
                      'Earn when students use your content',
                      'Creator badge',
                    ],
                    buttonText: 'Become a Creator',
                    isPopular: false,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required List<String> features,
    required String buttonText,
    required bool isPopular,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isPopular ? WebColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPopular ? null : Border.all(color: WebColors.border),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: WebColors.primary.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '⭐ MOST POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isPopular ? Colors.white : WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: isPopular ? Colors.white : WebColors.textPrimary,
                ),
              ),
              if (period.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 16,
                      color: isPopular
                          ? Colors.white.withOpacity(0.8)
                          : WebColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: isPopular
                  ? Colors.white.withOpacity(0.9)
                  : WebColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isPopular ? Colors.white : WebColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      feature,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            isPopular ? Colors.white : WebColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/auth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? Colors.white : WebColors.primary,
                foregroundColor: isPopular ? WebColors.primary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(BuildContext context) {
    final faqs = [
      {
        'q': 'How does the AI generate quizzes?',
        'a':
            'Our AI analyzes your content using advanced NLP to identify key concepts, then generates exam-style questions with accurate answers. It\'s trained on academic content patterns to ensure quality.',
      },
      {
        'q': 'Is my data secure and private?',
        'a':
            'Absolutely. All data is encrypted in transit and at rest. We never share your content with third parties, and you can delete your data at any time.',
      },
      {
        'q': 'Can I cancel my subscription anytime?',
        'a':
            'Yes! There are no contracts or commitments. You can upgrade, downgrade, or cancel anytime with one click. No questions asked.',
      },
      {
        'q': 'What file formats do you support?',
        'a':
            'We support PDF, Word documents, text files, images (with OCR), YouTube videos, and direct text input. More formats coming soon!',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: WebColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'FAQ',
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
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 60),
              ...faqs.map((faq) => _buildFAQItem(
                    question: faq['q']!,
                    answer: faq['a']!,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: WebColors.textPrimary,
          ),
        ),
        children: [
          Text(
            answer,
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

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(60),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WebColors.primary, const Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: WebColors.primary.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Ready to Transform Your Study Routine?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Join thousands of students who are already studying smarter, not harder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/auth'),
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Get Started Free'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: WebColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                    ),
                    child: const Text('Contact Sales'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '✓ Free forever plan  ✓ No credit card required  ✓ Cancel anytime',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
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
      color: const Color(0xFF1E293B),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 16),
                        Text(
                          'AI-powered study platform helping students\nachieve their academic goals.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildSocialIcon(Icons.language),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.alternate_email),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.chat_bubble),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildFooterColumn('Product', [
                    'Features',
                    'Pricing',
                    'Integrations',
                    'Changelog',
                  ]),
                  _buildFooterColumn('Company', [
                    'About Us',
                    'Blog',
                    'Careers',
                    'Contact',
                  ]),
                  _buildFooterColumn('Legal', [
                    'Privacy Policy',
                    'Terms of Service',
                    'Cookie Policy',
                    'Security',
                  ]),
                ],
              ),
              const SizedBox(height: 60),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 SumQuiz. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Made with ❤️ for students everywhere',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildFooterColumn(String title, List<String> links) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          ...links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                link,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
