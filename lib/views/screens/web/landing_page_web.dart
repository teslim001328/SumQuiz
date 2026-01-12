import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/views/screens/web/creator_tab_view.dart';
import 'package:sumquiz/views/widgets/web/glass_card.dart';
import 'package:sumquiz/views/widgets/web/neon_button.dart';
import 'package:sumquiz/views/widgets/web/particle_background.dart';
import 'package:sumquiz/views/widgets/web/exam_stats_card.dart';

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
    const backgroundColor = Color(0xFF0A0E27);
    const primaryColor = Color(0xFF6366F1);
    const secondaryColor = Color(0xFFEC4899);
    const accentCyan = Color(0xFF06B6D4);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated particle background
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 60,
              particleColor: Colors.white,
            ),
          ),
          // Gradient orbs
          Positioned(
            top: -150,
            right: -150,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 150, sigmaY: 150),
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withOpacity(0.3),
                      primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            left: -200,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 150, sigmaY: 150),
              child: Container(
                width: 700,
                height: 700,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      secondaryColor.withOpacity(0.25),
                      secondaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: 100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentCyan.withOpacity(0.2),
                      accentCyan.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          Column(
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
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      blur: 20,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    ).createShader(bounds),
                    child: Text(
                      "SumQuiz",
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: "For Students"),
                    Tab(text: "For Creators"),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    child: Text(
                      "Log In",
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeonButton(
                    text: "Get Started Free",
                    onPressed: () => context.go('/auth'),
                    icon: Icons.arrow_forward_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    glowColor: const Color(0xFF6366F1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.3);
  }

  Widget _buildHeroSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 1400),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  margin: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ).createShader(bounds),
                        child: Text(
                          "#1 AI-Powered Exam Prep Platform 2026",
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFB4B4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    "Master Any Exam\nWith AI Superpowers",
                    style: textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      fontSize: 72,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                const SizedBox(height: 24),
                Text(
                  "Transform any content into exam-ready summaries, quizzes, and flashcards in seconds. Stop cramming. Start mastering.",
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.7,
                    letterSpacing: 0.3,
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 48),
                Row(
                  children: [
                    NeonButton(
                      text: "Start Learning Free",
                      onPressed: () => context.go('/auth'),
                      icon: Icons.rocket_launch_rounded,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899)
                        ],
                      ),
                      glowColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 24),
                    ),
                    const SizedBox(width: 24),
                    NeonButton(
                      text: "Watch Demo",
                      onPressed: () {},
                      icon: Icons.play_circle_outline,
                      isOutlined: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 24),
                    ),
                  ],
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                const SizedBox(height: 40),
                Row(
                  children: [
                    _buildTrustBadge(Icons.verified_user, "100% Secure"),
                    const SizedBox(width: 24),
                    _buildTrustBadge(Icons.flash_on, "Instant Results"),
                    const SizedBox(width: 24),
                    _buildTrustBadge(Icons.trending_up, "10K+ Students"),
                  ],
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 5,
            child: _build3DPreviewCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF06B6D4), size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _build3DPreviewCard(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(-0.15)
        ..rotateX(0.05),
      child: GlassCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 60,
            offset: const Offset(-30, 30),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        child: Container(
          height: 550,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B).withOpacity(0.8),
                const Color(0xFF0F172A).withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            children: [
              // Mock browser header
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E27).withOpacity(0.5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(
                        3,
                        (i) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: [
                              const Color(0xFFEF4444),
                              const Color(0xFFFBBF24),
                              const Color(0xFF10B981)
                            ][i]
                                .withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mock summary card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withOpacity(0.1),
                              const Color(0xFF8B5CF6).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFF6366F1),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "AI Summary Generated",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(
                              3,
                              (i) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true))
                          .shimmer(
                              duration: 2000.ms,
                              color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 20),
                      // Mock quiz/flashcard cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMockCard(
                              Icons.quiz,
                              "Quiz",
                              const Color(0xFFEC4899),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMockCard(
                              Icons.style,
                              "Flashcards",
                              const Color(0xFF06B6D4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _buildMockCard(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Expanded(
                child: ExamStatsCard(
                  title: "Students Helped",
                  value: "10K+",
                  icon: Icons.people,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  animationDelay: 0,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ExamStatsCard(
                  title: "Quizzes Generated",
                  value: "50K+",
                  icon: Icons.quiz,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                  ),
                  animationDelay: 100,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ExamStatsCard(
                  title: "Success Rate",
                  value: "94%",
                  icon: Icons.trending_up,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                  ),
                  animationDelay: 200,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ExamStatsCard(
                  title: "Time Saved",
                  value: "10hrs",
                  icon: Icons.access_time,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  animationDelay: 300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final features = [
      {
        'icon': Icons.bolt,
        'gradient': const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
        'title': 'Lightning Fast',
        'desc':
            'Generate comprehensive study materials from 50-page PDFs in under 30 seconds.',
      },
      {
        'icon': Icons.psychology,
        'gradient': const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFF97316)]),
        'title': 'Exam-Focused AI',
        'desc':
            'Our AI is trained specifically on exam patterns to create test-ready questions.',
      },
      {
        'icon': Icons.school,
        'gradient': const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        'title': 'Smart Flashcards',
        'desc':
            'Spaced repetition algorithm ensures you remember what matters most.',
      },
      {
        'icon': Icons.video_library,
        'gradient': const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
        'title': 'YouTube Analysis',
        'desc':
            'Extract key concepts from educational videos with AI vision and audio analysis.',
      },
      {
        'icon': Icons.analytics,
        'gradient': const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
        'title': 'Progress Tracking',
        'desc':
            'Visualize your learning journey with detailed analytics and insights.',
      },
      {
        'icon': Icons.cloud_sync,
        'gradient': const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF6366F1)]),
        'title': 'Cloud Sync',
        'desc': 'Access your study materials anywhere, anytime, on any device.',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFB4B4FF)],
                ).createShader(bounds),
                child: Text(
                  "The Ultimate Exam Tech Stack",
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 48,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Everything you need to ace your exams, powered by cutting-edge AI",
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 80),
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
                    gradient: feature['gradient'] as Gradient,
                    title: feature['title'] as String,
                    desc: feature['desc'] as String,
                    delay: index * 100,
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
    required Gradient gradient,
    required String title,
    required String desc,
    required int delay,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (gradient as LinearGradient)
                        .colors
                        .first
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.7),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1);
  }

  Widget _buildHowItWorks(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFB4B4FF)],
                ).createShader(bounds),
                child: Text(
                  "How It Works",
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 48,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              _buildStep(
                number: "01",
                title: "Import Your Content",
                desc:
                    "Upload PDFs, paste text, drop YouTube links, or scan images. We support it all.",
                icon: Icons.upload_file,
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                alignRight: false,
                textTheme: textTheme,
              ),
              const SizedBox(height: 60),
              _buildStep(
                number: "02",
                title: "AI Extracts & Analyzes",
                desc:
                    "Our advanced AI reads, understands, and extracts key exam-focused concepts automatically.",
                icon: Icons.auto_awesome,
                gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF97316)]),
                alignRight: true,
                textTheme: textTheme,
              ),
              const SizedBox(height: 60),
              _buildStep(
                number: "03",
                title: "Study & Ace Your Exam",
                desc:
                    "Review summaries, take practice quizzes, and master flashcards. Track your progress in real-time.",
                icon: Icons.emoji_events,
                gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
                alignRight: false,
                textTheme: textTheme,
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
    required String desc,
    required IconData icon,
    required Gradient gradient,
    required bool alignRight,
    required TextTheme textTheme,
  }) {
    return Row(
      textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: GlassCard(
            padding: const EdgeInsets.all(40),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: alignRight
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (gradient as LinearGradient)
                            .colors
                            .first
                            .withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: alignRight ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    height: 1.6,
                  ),
                  textAlign: alignRight ? TextAlign.right : TextAlign.left,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: Text(
                number,
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(80),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.5),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.white, size: 64),
              const SizedBox(height: 32),
              Text(
                "Ready to Transform Your Study Game?",
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 48,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "Join 10,000+ students who are acing their exams with AI-powered study tools",
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              NeonButton(
                text: "Get Started Now - It's Free",
                onPressed: () => context.go('/auth'),
                icon: Icons.arrow_forward_rounded,
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ),
                glowColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.white.withOpacity(0.9), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "No credit card required",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.check_circle,
                      color: Colors.white.withOpacity(0.9), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Cancel anytime",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildFooter(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                              ).createShader(bounds),
                              child: Text(
                                "SumQuiz",
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "AI-powered exam preparation\nfor the future of learning.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFooterColumn(
                      "Product", ["Features", "Pricing", "FAQ", "Roadmap"]),
                  _buildFooterColumn(
                      "Company", ["About", "Blog", "Careers", "Contact"]),
                  _buildFooterColumn(
                      "Legal", ["Privacy", "Terms", "Security", "Cookies"]),
                ],
              ),
              const SizedBox(height: 60),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "© 2026 SumQuiz. Built for the future of learning.",
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  Row(
                    children: [
                      _buildSocialIcon(Icons.facebook),
                      const SizedBox(width: 16),
                      _buildSocialIcon(Icons.telegram),
                      const SizedBox(width: 16),
                      _buildSocialIcon(Icons.discord),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                link,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
      ),
    );
  }
}
