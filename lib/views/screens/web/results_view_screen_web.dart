import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/theme/web_theme.dart';
import 'package:sumquiz/models/flashcard.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/views/widgets/flashcards_view.dart';
import 'package:sumquiz/views/widgets/quiz_view.dart';
import 'package:sumquiz/views/widgets/summary_view.dart';

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
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Content saved to your library!'),
          ],
        ),
        backgroundColor: WebColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/library');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebColors.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: WebColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style:
                        TextStyle(color: WebColors.textPrimary, fontSize: 18),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: WebColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WebColors.secondaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(Icons.emoji_events, color: WebColors.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            'Your Study Materials',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: WebColors.textPrimary,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _saveToLibrary,
            icon: const Icon(Icons.check_circle),
            label: const Text('Save to Library'),
            style: ElevatedButton.styleFrom(
              backgroundColor: WebColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(left: 20, bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GENERATED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WebColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          if (_summary != null)
            _buildNavItem(0, 'Summary', Icons.article, WebColors.primary),
          if (_quiz != null)
            _buildNavItem(1, 'Quiz', Icons.quiz, WebColors.secondary),
          if (_flashcardSet != null)
            _buildNavItem(2, 'Flashcards', Icons.style, WebColors.accentPink),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, Color color) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withOpacity(0.1) : WebColors.backgroundAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : WebColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected ? color : WebColors.textSecondary,
                  size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : WebColors.textSecondary,
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
    return Container(
      margin: const EdgeInsets.only(right: 20, bottom: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _buildSelectedTabView().animate().fadeIn(duration: 300.ms),
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
