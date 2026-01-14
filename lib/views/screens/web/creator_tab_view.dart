import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/theme/web_theme.dart';

class CreatorTabView extends StatelessWidget {
  const CreatorTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For Content Creators',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Transform your educational content into interactive study materials',
                style: TextStyle(
                  fontSize: 18,
                  color: WebColors.textSecondary,
                ),
              ),
              const SizedBox(height: 60),
              _buildSection(
                'Perfect For',
                [
                  _buildForCard('Teachers & Educators', [
                    'Create study guides from lesson plans',
                    'Generate quizzes for students',
                    'Build flashcard sets for review'
                  ]),
                  _buildForCard('Content Creators', [
                    'Turn videos into study materials',
                    'Extract key points from articles',
                    'Create interactive learning content'
                  ]),
                  _buildForCard('Course Creators', [
                    'Generate course summaries',
                    'Create assessment materials',
                    'Build student resources'
                  ]),
                ],
              ),
              const SizedBox(height: 60),
              _buildSection(
                'Key Features',
                [
                  _buildFeatureCard(
                    'AI-Powered Extraction',
                    'Automatically extract key concepts from any content source',
                  ),
                  _buildFeatureCard(
                    'Multiple Formats',
                    'Generate summaries, quizzes, and flashcards from one source',
                  ),
                  _buildFeatureCard(
                    'Easy Sharing',
                    'Share study materials with students or followers',
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/create'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 24,
                    ),
                  ),
                  child: const Text('Start Creating'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: WebColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: children,
        ),
      ],
    );
  }

  Widget _buildForCard(String title, List<String> items) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
        boxShadow: WebColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        color: WebColors.secondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: WebColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: WebColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: WebColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
