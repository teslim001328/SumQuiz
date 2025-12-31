import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:sumquiz/models/spaced_repetition.dart';
import 'package:sumquiz/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/usage_service.dart';
import '../../models/user_model.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../widgets/upgrade_dialog.dart';
import 'package:sumquiz/views/widgets/flashcards_view.dart';

enum FlashcardState { creation, loading, review, finished, error }

class FlashcardsScreen extends StatefulWidget {
  final FlashcardSet? flashcardSet;
  const FlashcardsScreen({super.key, this.flashcardSet});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final EnhancedAIService _aiService = EnhancedAIService();
  final Uuid _uuid = const Uuid();
  late SpacedRepetitionService _srsService;
  late LocalDatabaseService _localDbService;

  FlashcardState _state = FlashcardState.creation;
  String _loadingMessage = 'Generating Flashcards...';
  String _errorMessage = '';

  List<Flashcard> _flashcards = [];
  int _correctCount = 0;
  bool get _isCreationMode => widget.flashcardSet == null;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    if (widget.flashcardSet != null) {
      setState(() {
        _flashcards = widget.flashcardSet!.flashcards;
        _titleController.text = widget.flashcardSet!.title;
        _state = FlashcardState.review;
      });
    }
  }

  Future<void> _initializeServices() async {
    _localDbService = LocalDatabaseService();
    await _localDbService.init();
    _srsService =
        SpacedRepetitionService(_localDbService as Box<SpacedRepetitionItem>);
  }

  Future<void> _generateFlashcards() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      setState(() {
        _state = FlashcardState.error;
        _errorMessage = 'Please fill in both the title and content fields.';
      });
      return;
    }

    final userModel = Provider.of<UserModel?>(context, listen: false);
    final usageService = Provider.of<UsageService?>(context, listen: false);
    if (userModel == null || usageService == null) {
      setState(() {
        _state = FlashcardState.error;
        _errorMessage = 'User not found.';
      });
      return;
    }

    if (!userModel.isPro) {
      final canGenerate = await usageService.canPerformAction('flashcards');
      if (!canGenerate) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) =>
                const UpgradeDialog(featureName: 'flashcards'),
          );
        }
        return;
      }
    }

    setState(() {
      _state = FlashcardState.loading;
      _loadingMessage = 'Generating flashcards...';
    });

    try {
      developer.log('Generating flashcards for content...',
          name: 'flashcards.generation');

      final folderId = await _aiService.generateAndStoreOutputs(
        text: _textController.text,
        title: _titleController.text,
        requestedOutputs: ['flashcards'],
        userId: userModel.uid,
        localDb: _localDbService,
        onProgress: (message) {
          setState(() {
            _loadingMessage = message;
          });
        },
      );

      if (!userModel.isPro) {
        await usageService.recordAction('flashcards');
      }

      final content = await _localDbService.getFolderContents(folderId);
      final flashcardSetId =
          content.firstWhere((c) => c.contentType == 'flashcardSet').contentId;
      final flashcardSet =
          await _localDbService.getFlashcardSet(flashcardSetId);

      if (flashcardSet != null && flashcardSet.flashcards.isNotEmpty) {
        if (mounted) {
          setState(() {
            _flashcards = flashcardSet.flashcards
                .map((f) =>
                    Flashcard(id: f.id, question: f.question, answer: f.answer))
                .toList();
            _state = FlashcardState.review;
          });
          developer.log(
              '${_flashcards.length} flashcards generated successfully.',
              name: 'flashcards.generation');
        }
      } else {
        throw Exception('AI service returned an empty list of flashcards.');
      }
    } catch (e, s) {
      if (mounted) {
        setState(() {
          _state = FlashcardState.error;
          _errorMessage = 'Error generating flashcards: $e';
        });
        if (e.toString().contains('quota')) {
          showDialog(
            context: context,
            builder: (context) =>
                const UpgradeDialog(featureName: 'flashcards'),
          );
        }
        developer.log('Error generating flashcards',
            name: 'flashcards.generation', error: e, stackTrace: s);
      }
    }
  }

  Future<void> _saveFlashcardSet() async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save a set.')),
      );
      return;
    }

    if (_flashcards.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Cannot save an empty set or a set without a title.')),
      );
      return;
    }

    setState(() => _state = FlashcardState.loading);

    try {
      final set = FlashcardSet(
        id: widget.flashcardSet?.id ?? _uuid.v4(),
        title: _titleController.text,
        flashcards: _flashcards,
        timestamp: Timestamp.now(),
      );

      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      if (_isCreationMode) {
        await firestoreService.addFlashcardSet(userModel.uid, set);
      } else {
        await firestoreService.updateFlashcardSet(
            userModel.uid, set.id, set.title, set.flashcards);
      }

      for (final flashcard in _flashcards) {
        await _srsService.scheduleReview(flashcard.id, userModel.uid);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard set saved and scheduled for review!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, s) {
      developer.log('Error saving flashcard set or scheduling reviews',
          name: 'flashcards.save', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _state = FlashcardState.error;
          _errorMessage = 'Error saving set: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _state = FlashcardState.review);
      }
    }
  }

  void _reviewAgain() {
    setState(() {
      _state = FlashcardState.review;
      _correctCount = 0;
    });
  }

  void _retry() {
    setState(() {
      _state = FlashcardState.creation;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title:
              Text(_isCreationMode ? 'Create Flashcards' : 'Review Flashcards'),
          actions: [
            if (_flashcards.isNotEmpty && _state == FlashcardState.review)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveFlashcardSet,
                tooltip: 'Save Set',
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildContent(),
          ),
        ));
  }

  Widget _buildContent() {
    switch (_state) {
      case FlashcardState.loading:
        return _buildLoadingState();
      case FlashcardState.error:
        return _buildErrorState();
      case FlashcardState.review:
        return _buildReviewInterface();
      case FlashcardState.finished:
        return _buildCompletionScreen();
      default:
        return _buildCreationForm();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(_loadingMessage),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text('Oops! Something went wrong.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_errorMessage, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _retry, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildCreationForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text('Create a New Flashcard Set',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Title',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Biology Chapter 5',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Content to Generate From',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText:
                          'Paste your notes, an article, or any text here.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateFlashcards,
                icon: const Icon(Icons.bolt_outlined),
                label: const Text('Generate Flashcards'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewInterface() {
    return FlashcardsView(
      title: _titleController.text,
      flashcards: _flashcards,
      onReview: (index, knewIt) {
        final flashcardId = _flashcards[index].id;
        _srsService.updateReview(flashcardId, knewIt);
        if (knewIt) _correctCount++;
      },
      onFinish: () {
        setState(() => _state = FlashcardState.finished);
      },
    );
  }

  Widget _buildCompletionScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 100),
          const SizedBox(height: 24),
          Text('Set Complete!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('You got $_correctCount out of ${_flashcards.length} correct.',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 40),
          if (_isCreationMode) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: _saveFlashcardSet,
                label: const Text('Save Flashcards'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: _reviewAgain,
              label: const Text('Review Again'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
                onPressed: () {
                  double score = _flashcards.isEmpty
                      ? 0
                      : _correctCount / _flashcards.length;
                  Navigator.of(context).pop(score);
                },
                child: const Text('Finish')),
          ),
        ],
      ),
    );
  }
}
