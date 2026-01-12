import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/models/flashcard.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/views/widgets/flashcards_view.dart';
import 'package:sumquiz/views/widgets/quiz_view.dart';
import 'package:sumquiz/views/widgets/summary_view.dart';
import 'package:sumquiz/views/widgets/web/glass_card.dart';
import 'package:sumquiz/views/widgets/web/neon_button.dart';
import 'package:sumquiz/views/widgets/web/particle_background.dart';

class ResultsViewScreenWeb extends StatefulWidget {
  final String folderId;

  const ResultsViewScreenWeb({super.key, required this.folderId});

  @override
  State<ResultsViewScreenWeb> createState() => _ResultsViewScreenWebState();
}

class _ResultsViewScreenWebState extends State<ResultsViewScreenWeb> {
  int _selectedTab = 0;
  bool _isLoading = true;
  String? _errorMessage;

  LocalSummary? _summary;
  LocalQuiz? _quiz;
  LocalFlashcardSet? _flashcardSet;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = context.read<LocalDatabaseService>();
      final contents = await db.getFolderContents(widget.folderId);

      for (var content in contents) {
        if (content.contentType == 'summary') {
          _summary = await db.getSummary(content.contentId);
        } else if (content.contentType == 'quiz') {
          _quiz = await db.getQuiz(content.contentId);
        } else if (content.contentType == 'flashcardSet') {
          _flashcardSet = await db.getFlashcardSet(content.contentId);
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load results: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveToLibrary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Content saved to your library!'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/library');
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0A0E27);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Particle background
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 30,
              particleColor: Colors.white,
            ),
          ),
          // Gradient orb
          Positioned(
            top: 200,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.2),
                      const Color(0xFF10B981).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                )
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    )
                  : Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: Row(
                            children: [
                              _buildSidebar(),
                              Expanded(child: _buildContent()),
                            ],
                          ),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      blur: 20,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.emoji_events, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Text(
            'Your Study Materials',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          NeonButton(
            text: 'Save to Library',
            onPressed: _saveToLibrary,
            icon: Icons.check_circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
            ),
            glowColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return GlassCard(
      margin: const EdgeInsets.only(left: 20, bottom: 20),
      padding: const EdgeInsets.all(24),
      blur: 20,
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            if (_summary != null)
              _buildNavItem(
                0,
                'Summary',
                Icons.article,
                const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
            if (_quiz != null)
              _buildNavItem(
                1,
                'Quiz',
                Icons.quiz,
                const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                ),
              ),
            if (_flashcardSet != null)
              _buildNavItem(
                2,
                'Flashcards',
                Icons.style,
                const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, String label, IconData icon, Gradient gradient) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: !isSelected ? Colors.white.withOpacity(0.03) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (gradient as LinearGradient)
                          .colors
                          .first
                          .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(40),
        margin: EdgeInsets.zero,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _buildSelectedTabView()
                .animate()
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabView() {
    switch (_selectedTab) {
      case 0:
        return _buildSummaryTab();
      case 1:
        return _buildQuizzesTab();
      case 2:
        return _buildFlashcardsTab();
      default:
        return Container();
    }
  }

  Widget _buildSummaryTab() {
    if (_summary == null) return const SizedBox();
    return SummaryView(
      title: _summary!.title,
      content: _summary!.content,
      tags: _summary!.tags,
      showActions: true,
      onCopy: () {
        Clipboard.setData(ClipboardData(text: _summary!.content));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary copied to clipboard')),
        );
      },
    );
  }

  Widget _buildQuizzesTab() {
    if (_quiz == null) return const SizedBox();
    return QuizView(
      title: _quiz!.title,
      questions: _quiz!.questions,
      onAnswer: (isCorrect) {},
      onFinish: () {},
    );
  }

  Widget _buildFlashcardsTab() {
    if (_flashcardSet == null) return const SizedBox();

    final flashcards = _flashcardSet!.flashcards
        .map((f) => Flashcard(
              id: f.id,
              question: f.question,
              answer: f.answer,
            ))
        .toList();

    return Center(
      child: SizedBox(
        height: 600,
        child: FlashcardsView(
          title: _flashcardSet!.title,
          flashcards: flashcards,
          onReview: (index, knewIt) {},
          onFinish: () {},
        ),
      ),
    );
  }
}
