import 'package:flutter/material.dart';
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
  final List<Flashcard> _incorrectFlashcards = [];
  bool _reviewFinished = false;

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.go('/'), // Navigate home
        ),
        title: Text('Results', style: theme.textTheme.titleLarge),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.library_add_check_outlined,
                color: theme.iconTheme.color),
            tooltip: 'Save to Library',
            onPressed: _saveToLibrary,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.secondary))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error)))
              : Column(
                  children: [
                    _buildOutputSelector(),
                    Expanded(child: _buildSelectedTabView()),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.secondary,
        child: Icon(Icons.edit_note, color: theme.colorScheme.onSecondary),
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

    final flashcards = _flashcardSet!.flashcards
        .map((f) => Flashcard(
              id: f.id,
              question: f.question,
              answer: f.answer,
            ))
        .toList();

    if (_reviewFinished) {
      return _buildFlashcardCompletionScreen(flashcards.length);
    }

    return FlashcardsView(
      title: _flashcardSet!.title,
      flashcards: flashcards,
      onReview: (index, knewIt) {
        if (!knewIt) {
          if (!_incorrectFlashcards.contains(flashcards[index])) {
            _incorrectFlashcards.add(flashcards[index]);
          }
        }
      },
      onFinish: () {
        setState(() {
          _reviewFinished = true;
        });
      },
    );
  }

  Widget _buildFlashcardCompletionScreen(int totalCards) {
    final theme = Theme.of(context);
    final correctCount = totalCards - _incorrectFlashcards.length;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
          const SizedBox(height: 20),
          Text('Review Complete!', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text('You got $correctCount out of $totalCards correct.',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 30),
          if (_incorrectFlashcards.isNotEmpty) ...[
            Text('Flashcards to review again:', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _incorrectFlashcards.length,
              itemBuilder: (context, index) {
                final card = _incorrectFlashcards[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(card.question),
                    subtitle: Text(card.answer),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _reviewFinished = false;
                  _incorrectFlashcards.clear();
                });
              },
              child: const Text('Review Again'),
            ),
          ),
        ]));
  }
}
