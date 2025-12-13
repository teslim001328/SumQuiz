import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/local_database_service.dart';
import 'package:myapp/models/folder.dart';
import 'package:myapp/models/local_summary.dart';
import 'package:myapp/models/local_quiz.dart';
import 'package:myapp/models/local_flashcard_set.dart';
import 'package:myapp/models/flashcard_set.dart';
import 'package:myapp/models/flashcard.dart';
import 'package:myapp/views/screens/quiz_screen.dart';
import 'package:myapp/views/screens/flashcards_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String folderId;

  const ResultsScreen({super.key, required this.folderId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  Folder? _folder;
  LocalSummary? _summary;
  LocalQuiz? _quiz;
  LocalFlashcardSet? _flashcardSet;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final db = context.read<LocalDatabaseService>();
      await db.init();

      _folder = await db.getFolder(widget.folderId);
      if (_folder == null) {
        throw Exception('Folder not found');
      }

      final contents = await db.getFolderContents(widget.folderId);

      for (final content in contents) {
        switch (content.contentType) {
          case 'summary':
            _summary = await db.getSummary(content.contentId);
            break;
          case 'quiz':
            _quiz = await db.getQuiz(content.contentId);
            break;
          case 'flashcards':
            _flashcardSet = await db.getFlashcardSet(content.contentId);
            break;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_folder?.name ?? 'Result'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.hintColor,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Summary', icon: Icon(Icons.summarize)),
            Tab(text: 'Quiz', icon: Icon(Icons.quiz)),
            Tab(text: 'Flashcards', icon: Icon(Icons.style)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildQuizTab(),
          _buildFlashcardsTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_summary == null) return _buildEmptyState('No summary generated');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_summary!.title,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children:
                _summary!.tags.map((tag) => Chip(label: Text(tag))).toList(),
          ),
          const SizedBox(height: 24),
          Text(_summary!.content,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildQuizTab() {
    if (_quiz == null) return _buildEmptyState('No quiz generated');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text(_quiz!.title, style: Theme.of(context).textTheme.headlineSmall),
          Text('${_quiz!.questions.length} Questions',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Quiz'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => QuizScreen(quiz: _quiz)),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildFlashcardsTab() {
    if (_flashcardSet == null) {
      return _buildEmptyState('No flashcards generated');
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style, size: 80, color: Colors.purple),
          const SizedBox(height: 16),
          Text(_flashcardSet!.title,
              style: Theme.of(context).textTheme.headlineSmall),
          Text('${_flashcardSet!.flashcards.length} Cards',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Review Flashcards'),
            onPressed: () {
              final domainSet = _mapLocalToFlashcardSet(_flashcardSet!);
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => FlashcardsScreen(flashcardSet: domainSet)),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.not_interested, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  FlashcardSet? _mapLocalToFlashcardSet(LocalFlashcardSet local) {
    return FlashcardSet(
      id: local.id,
      title: local.title,
      flashcards: local.flashcards
          .map((lf) => Flashcard(
                id: lf.id, // Use local ID. LocalFlashcard has ID.
                question: lf.question,
                answer: lf.answer,
              ))
          .toList(),
      timestamp: Timestamp.fromDate(local.timestamp),
    );
  }
}
