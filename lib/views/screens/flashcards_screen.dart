import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:sumquiz/models/spaced_repetition.dart';
import 'package:sumquiz/services/firestore_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

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
          developer.log('First flashcard: ${_flashcards.first.question}',
              name: 'flashcards.debug');
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
              _isCreationMode ? 'Create Flashcards' : 'Review Flashcards',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          actions: [
            if (_flashcards.isNotEmpty && _state == FlashcardState.review)
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: _saveFlashcardSet,
                tooltip: 'Save Set',
              ),
          ],
        ),
        body: Stack(
          children: [
            // Darker Animated Gradient for Focus Mode
            Animate(
              onPlay: (controller) => controller.repeat(reverse: true),
              effects: [
                CustomEffect(
                  duration: 8.seconds,
                  builder: (context, value, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF283593), // Indigo 800
                            Color.lerp(const Color(0xFF283593),
                                const Color(0xFF1A237E), value)!, // Indigo 900
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
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
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ),
          const SizedBox(height: 32),
          Text(_loadingMessage,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildGlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.orangeAccent, size: 64),
              const SizedBox(height: 16),
              Text('Oops! Something went wrong.',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildCreationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text('Create a New Flashcard Set',
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))
              .animate()
              .fadeIn()
              .slideY(begin: -0.2),
          const SizedBox(height: 32),
          _buildGlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set Title',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., Biology Chapter 5',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Content to Generate From',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  maxLines: 10,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Paste your notes, an article, or any text here.',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generateFlashcards,
                icon: const Icon(Icons.bolt_outlined),
                label: const Text('Generate Flashcards',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: const Color(0xFF1A1A1A),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).scale(),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: _buildGlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.greenAccent, size: 80),
              const SizedBox(height: 24),
              Text('Set Complete!',
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Text(
                  'You got $_correctCount out of ${_flashcards.length} correct.',
                  style:
                      GoogleFonts.inter(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 40),
              if (_isCreationMode) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    onPressed: _saveFlashcardSet,
                    label: const Text('Save Flashcards',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: _reviewAgain,
                  label: const Text('Review Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                    onPressed: () {
                      double score = _flashcards.isEmpty
                          ? 0
                          : _correctCount / _flashcards.length;
                      Navigator.of(context).pop(score);
                    },
                    child: const Text('Finish',
                        style: TextStyle(color: Colors.white70))),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  Widget _buildGlassContainer(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
