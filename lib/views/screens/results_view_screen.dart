import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/models/folder.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
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

  Folder? _folder;
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
      _folder = await db.getFolder(widget.folderId);
      final contents = await db.getFolderContents(widget.folderId);

      for (var content in contents) {
        if (content.contentType == 'summary') {
          _summary = await db.getSummary(content.contentId);
        } else if (content.contentType == 'quiz') {
          _quiz = await db.getQuiz(content.contentId);
        } else if (content.contentType == 'flashcards') {
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
            icon: Icon(Icons.library_add_check_outlined, color: theme.iconTheme.color),
            tooltip: 'Save to Library',
            onPressed: _saveToLibrary,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)))
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
                  color: isSelected ? theme.colorScheme.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: theme.textTheme.labelLarge?.copyWith(
                       color: isSelected ? theme.colorScheme.onSecondary : theme.textTheme.bodyLarge?.color,
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

  Widget _buildAIGeneratedCard() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.secondary, size: 40),
          const SizedBox(height: 8),
          Text('AI GENERATED', style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final theme = Theme.of(context);
    if (_summary == null) return Center(child: Text('No summary available.', style: theme.textTheme.bodyMedium));

    final mainConcepts = _summary!.tags.isNotEmpty
        ? _summary!.tags
        : ['Cognitive Load Theory', 'Progressive Disclosure', 'User Engagement'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIGeneratedCard(),
          const SizedBox(height: 24),
          Text('Key Takeaways', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            _summary!.content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 32),
          Text('Main Concepts', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          ...mainConcepts.map((concept) => _buildConceptCard(concept, 'Minimizing mental effort leads to better learning outcomes.')),
        ],
      ),
    );
  }

  Widget _buildConceptCard(String title, String subtitle) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesTab() {
    final theme = Theme.of(context);
    if (_quiz == null) return Center(child: Text('No quiz available.', style: theme.textTheme.bodyMedium));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quiz!.questions.length,
      itemBuilder: (context, index) {
        final question = _quiz!.questions[index];
        return Card(
          color: theme.cardColor,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Question ${index + 1}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary)),
                const SizedBox(height: 8),
                Text(question.question, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                ...question.options.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('• $opt', style: theme.textTheme.bodyMedium),
                )),
                 const SizedBox(height: 8),
                Text('Answer: ${question.correctAnswer}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.greenAccent)),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlashcardsTab() {
    final theme = Theme.of(context);
    if (_flashcardSet == null || _flashcardSet!.flashcards.isEmpty) {
      return Center(child: Text('No flashcards available.', style: theme.textTheme.bodyMedium));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flashcardSet!.flashcards.length,
      itemBuilder: (context, index) {
        final card = _flashcardSet!.flashcards[index];
        return Card(
          color: theme.cardColor,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Front', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary)),
                const SizedBox(height: 8),
                Text(card.question, style: theme.textTheme.bodyLarge),
                Divider(color: theme.dividerColor, height: 32),
                Text('Back', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary)),
                const SizedBox(height: 8),
                Text(card.answer, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}
