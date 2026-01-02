import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/local_database_service.dart';

import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
import 'package:flutter/services.dart';
import 'package:sumquiz/models/flashcard.dart';
import 'package:sumquiz/views/widgets/summary_view.dart';
import 'package:sumquiz/views/widgets/quiz_view.dart';
import 'package:sumquiz/views/widgets/flashcards_view.dart';
import 'package:go_router/go_router.dart';

class ResultsViewScreen extends StatefulWidget {
  final String folderId;

  const ResultsViewScreen({super.key, required this.folderId});

  @override
  State<ResultsViewScreen> createState() => _ResultsViewScreenState();
}

class _ResultsViewScreenState extends State<ResultsViewScreen> {
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
      ),
    );
    context.go('/library');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Results',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_check_outlined,
                color: Colors.white),
            tooltip: 'Save to Library',
            onPressed: _saveToLibrary,
          ),
        ],
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style: GoogleFonts.inter(color: Colors.redAccent)))
                    : Column(
                        children: [
                          _buildOutputSelector()
                              .animate()
                              .fadeIn()
                              .slideY(begin: -0.2),
                          Expanded(
                              child: _buildSelectedTabView()
                                  .animate()
                                  .fadeIn(delay: 200.ms)),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.edit_note, color: Colors.white),
      ),
    );
  }

  Widget _buildOutputSelector() {
    final theme = Theme.of(context);
    const tabs = ['Summary', 'Quizzes', 'Flashcards'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 48,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onSecondary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
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
    final theme = Theme.of(context);
    if (_summary == null) {
      return Center(
          child:
              Text('No summary available.', style: theme.textTheme.bodyMedium));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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

  Widget _buildQuizzesTab() {
    final theme = Theme.of(context);
    if (_quiz == null) {
      return Center(
          child: Text('No quiz available.', style: theme.textTheme.bodyMedium));
    }

    return QuizView(
      title: _quiz!.title,
      questions: _quiz!.questions,
      onAnswer: (isCorrect) {}, // Optional: track score locally if needed
      onFinish: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz practice finished!')),
        );
      },
    );
  }

  Widget _buildFlashcardsTab() {
    final theme = Theme.of(context);
    if (_flashcardSet == null || _flashcardSet!.flashcards.isEmpty) {
      return Center(
          child: Text('No flashcards available.',
              style: theme.textTheme.bodyMedium));
    }

    // Convert LocalFlashcard to Flashcard model if necessary, or ensure generic type match.
    // FlashcardSet in models/local_flashcard_set.dart uses LocalFlashcard.
    // Flashcard in models/flashcard.dart is what FlashcardsView expects?
    // Let's check imports in FlashcardsView. It imports models/flashcard.dart.
    // LocalFlashcardSet has List<LocalFlashcard>.
    // I need to map LocalFlashcard to Flashcard.

    // Actually, let's verify models compatibility.
    // LocalFlashcard usually has id, question, answer.
    // Flashcard has id, question, answer.

    final flashcards = _flashcardSet!.flashcards
        .map((f) => Flashcard(
              id: f.id,
              question: f.question,
              answer: f.answer,
            ))
        .toList();

    return FlashcardsView(
      title: _flashcardSet!.title,
      flashcards: flashcards,
      onReview: (index, knewIt) {},
      onFinish: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcard review finished!')),
        );
      },
    );
  }
}
