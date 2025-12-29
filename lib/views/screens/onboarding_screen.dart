import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go('/auth');
  }

  void _navigateToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  OnboardingPage(
                    title: 'From Lecture to Legend. Instantly.',
                    subtitle: 'Drop in your notes, and let our AI create perfect summaries and practice quizzes for you in seconds.',
                    imagePath: 'assets/images/onboarding_learn.svg',
                  ),
                  OnboardingPage(
                    title: 'Your Notes, Now a Superpower.',
                    subtitle: 'Generate flashcards, track your progress, and conquer any subject with a personalized learning toolkit.',
                    imagePath: 'assets/images/onboarding_notes.svg',
                  ),
                  OnboardingPage(
                    title: 'Master Any Subject.',
                    subtitle: 'Start your first SumQuiz for free and transform the way you study, forever.',
                    imagePath: 'assets/images/onboarding_rocket.svg',
                  ),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildDot(index)),
          ),
          const SizedBox(height: 48),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _currentPage == 2 ? _buildGetStartedButtons() : _buildNextButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedButtons() {
    return Column(
      key: const ValueKey('getStartedButtons'),
      children: [
        ElevatedButton(
          onPressed: _finishOnboarding,
          child: const Text('Get Started Free'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _finishOnboarding,
          child: const Text('Already have an account? Sign In'),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      key: const ValueKey('nextButton'),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToNextPage,
        child: const Text('Next'),
      ),
    );
  }

  Widget _buildDot(int index) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                imagePath,
                height: 250,
                width: double.infinity,
                placeholderBuilder: (BuildContext context) => Container(
                  padding: const EdgeInsets.all(30.0),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(height: 56),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
