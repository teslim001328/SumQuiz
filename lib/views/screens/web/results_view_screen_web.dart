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
        content: const Text('Content saved to your library!'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        width: 400,
      ),
    );
    context.go('/library');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Preparation Results',
          style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _saveToLibrary,
              icon: Icon(Icons.check_circle_outline,
                  size: 20, color: theme.colorScheme.onPrimary),
              label: Text("Save & Continue",
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!, style: theme.textTheme.bodyLarge))
              : Row(
                  children: [
                    // Sidebar
                    Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border(
                            right: BorderSide(color: theme.dividerColor)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text("Generated Content",
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5))),
                          ),
                          _buildNavItem(0, "Summary", Icons.article_outlined,
                              _summary != null, theme),
                          _buildNavItem(1, "Quiz", Icons.quiz_outlined,
                              _quiz != null, theme),
                          _buildNavItem(
                              2,
                              "Flashcards",
                              Icons.view_carousel_outlined,
                              _flashcardSet != null,
                              theme),
                        ],
                      ),
                    ),
                    // Main Content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: _buildSelectedTabView(theme)
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideX(begin: 0.1, curve: Curves.easeOut),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, bool hasContent,
      ThemeData theme) {
    if (!hasContent) return const SizedBox.shrink();

    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            const Spacer(),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary, shape: BoxShape.circle),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabView(ThemeData theme) {
    switch (_selectedTab) {
      case 0:
        return _buildSummaryTab(theme);
      case 1:
        return _buildQuizzesTab(theme);
      case 2:
        return _buildFlashcardsTab(theme);
      default:
        return Container();
    }
  }

  Widget _buildSummaryTab(ThemeData theme) {
    if (_summary == null) return const SizedBox();
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SummaryView(
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
        ),
      ),
    );
  }

  Widget _buildQuizzesTab(ThemeData theme) {
    if (_quiz == null) return const SizedBox();
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: QuizView(
          title: _quiz!.title,
          questions: _quiz!.questions,
          onAnswer: (isCorrect) {},
          onFinish: () {},
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab(ThemeData theme) {
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
        height: 600, // Constrain height for the card swiper
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
