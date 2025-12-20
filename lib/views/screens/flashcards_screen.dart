import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:sumquiz/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/usage_service.dart';
import '../../models/user_model.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../../models/summary_model.dart';
import '../widgets/upgrade_dialog.dart';

class FlashcardsScreen extends StatefulWidget {
  final FlashcardSet? flashcardSet;
  const FlashcardsScreen({super.key, this.flashcardSet});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final CardSwiperController _swiperController = CardSwiperController();
  final EnhancedAIService _aiService = EnhancedAIService();
  final Uuid _uuid = const Uuid();
  late SpacedRepetitionService _srsService;

  bool _isLoading = false;
  bool _isReviewFinished = false;
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
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
      });
    }
  }

  Future<void> _initializeServices() async {
    final dbService = LocalDatabaseService();
    await dbService.init();
    _srsService = SpacedRepetitionService(dbService.getSpacedRepetitionBox());
  }

  Future<void> _generateFlashcards() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in both the title and content fields.')),
      );
      return;
    }

    final userModel = Provider.of<UserModel?>(context, listen: false);
    final usageService = Provider.of<UsageService?>(context, listen: false);
    if (userModel == null || usageService == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not found.')));
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

    setState(() => _isLoading = true);

    try {
      developer.log('Generating flashcards for content...',
          name: 'flashcards.generation');
      final summary = Summary(
        id: '', // Temporary ID
        userId: userModel.uid,
        title: _titleController.text,
        content: _textController.text,
        timestamp: Timestamp.now(),
      );
      final cards = await _aiService.generateFlashcards(summary);

      if (cards.isNotEmpty) {
        if (!userModel.isPro) {
          await usageService.recordAction('flashcards');
        }
        // Assign unique IDs to each card
        final cardsWithIds = cards
            .map((card) => Flashcard(
                id: _uuid.v4(), question: card.question, answer: card.answer))
            .toList();

        if (mounted) {
          setState(() {
            _flashcards = cardsWithIds;
            _isLoading = false;
          });
          developer.log('${cards.length} flashcards generated successfully.',
              name: 'flashcards.generation');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not generate flashcards from the provided content. Please try again with different text.'),
              backgroundColor: Colors.orange,
            ),
          );
          developer.log('AI service returned an empty list of flashcards.',
              name: 'flashcards.generation');
        }
      }
    } catch (e, s) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.toString().contains('quota')) {
          showDialog(
            context: context,
            builder: (context) =>
                const UpgradeDialog(featureName: 'flashcards'),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error generating flashcards: $e')));
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

    setState(() => _isLoading = true);

    try {
      final set = FlashcardSet(
        id: '', // Firestore will generate this
        title: _titleController.text,
        flashcards: _flashcards,
        timestamp: Timestamp.now(),
      );

      // Save the set to Firestore
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.addFlashcardSet(userModel.uid, set);

      // Schedule each flashcard for review
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving set: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleFlashcardReview(int index, bool knewIt) {
    // Now using the persistent ID
    final flashcardId = _flashcards[index].id;
    _srsService.updateReview(flashcardId, knewIt);
    if (knewIt) _correctCount++;
    _swiperController.swipe(CardSwiperDirection.right);
  }

  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (currentIndex == null) {
      setState(() => _isReviewFinished = true);
    } else {
      setState(() {
        _currentIndex = currentIndex;
      });
    }
    return true;
  }

  void _reviewAgain() {
    setState(() {
      _isReviewFinished = false;
      _currentIndex = 0;
      _swiperController.moveTo(0);
    });
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
            icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_flashcards.isNotEmpty && !_isReviewFinished && _isCreationMode)
              IconButton(
                icon: Icon(Icons.save, color: theme.iconTheme.color),
                onPressed: _saveFlashcardSet,
                tooltip: 'Save Set',
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildContent(theme),
          ),
        ));
  }

  Widget _buildContent(ThemeData theme) {
    if (_isReviewFinished) {
      return _buildCompletionScreen(theme);
    } else if (_flashcards.isNotEmpty) {
      return _buildReviewInterface(theme);
    } else {
      return _buildCreationForm(theme);
    }
  }

  Widget _buildCreationForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text('Create Flashcards', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Title', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter set title',
                      hintStyle:
                          TextStyle(color: theme.textTheme.bodySmall?.color),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Content', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 10,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter content',
                      hintStyle:
                          TextStyle(color: theme.textTheme.bodySmall?.color),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
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
                onPressed: _isLoading ? null : _generateFlashcards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.bolt_outlined),
                label: Text(
                  _isLoading
                      ? 'Generating Flashcards...'
                      : 'Generate Flashcards',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewInterface(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(_titleController.text,
                        style: theme.textTheme.headlineSmall),
                    Text('Question ${_currentIndex + 1}/${_flashcards.length}',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            Expanded(
              child: CardSwiper(
                controller: _swiperController,
                cardsCount: _flashcards.length,
                onSwipe: _onSwipe,
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) {
                  final card = _flashcards[index];
                  return FlipCard(
                    front: _buildCardSide(theme, card.question, isFront: true),
                    back: _buildCardSide(theme, card.answer,
                        isFront: false, cardIndex: index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSide(ThemeData theme, String text,
      {required bool isFront, int? cardIndex}) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [theme.cardColor, theme.cardColor.withAlpha(204)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(128),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          Expanded(
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(text,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge)))),
          if (!isFront)
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeedbackButton("Didn't Know",
                        () => _handleFlashcardReview(cardIndex!, false), false),
                    _buildFeedbackButton("Knew It",
                        () => _handleFlashcardReview(cardIndex!, true), true),
                  ],
                ))
          else
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Tap to Flip",
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(
      String text, VoidCallback onPressed, bool knewIt) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            knewIt ? Colors.green.withAlpha(51) : Colors.red.withAlpha(51),
        foregroundColor: knewIt ? Colors.greenAccent : Colors.redAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: knewIt ? Colors.greenAccent : Colors.redAccent,
                width: 1.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildCompletionScreen(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text('Set Complete!', style: theme.textTheme.headlineMedium),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.greenAccent, size: 100),
                const SizedBox(height: 24),
                Text("You've completed the set!",
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 40),
                if (_isCreationMode) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveFlashcardSet,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Save Flashcards',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _reviewAgain,
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.onSurface),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text('Review Again',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
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
                      child: Text('Finish',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodySmall?.color))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
