import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:uuid/uuid.dart';

import '../../models/user_model.dart';
import '../../models/local_quiz.dart';
import '../../models/local_quiz_question.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/local_database_service.dart';
import '../../services/usage_service.dart';
import '../../view_models/quiz_view_model.dart';
import '../widgets/upgrade_dialog.dart';
import '../widgets/quiz_view.dart';

enum QuizState { creation, loading, inProgress, finished, error }

class QuizScreen extends StatefulWidget {
  final LocalQuiz? quiz;
  final String? initialText;
  final String? initialTitle;

  const QuizScreen({
    super.key,
    this.quiz,
    this.initialText,
    this.initialTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final EnhancedAIService _aiService = EnhancedAIService();
  final LocalDatabaseService _localDbService = LocalDatabaseService();

  QuizState _state = QuizState.creation;
  String _loadingMessage = 'Generating Quiz...';
  String _errorMessage = '';

  late List<LocalQuizQuestion> _questions;

  int _score = 0;
  String? _quizId;

  @override
  void initState() {
    super.initState();
    _localDbService.init();

    if (widget.quiz != null) {
      _questions = widget.quiz!.questions;
      _titleController.text = widget.quiz!.title;
      _quizId = widget.quiz!.id;
      _state = QuizState.inProgress;
    } else {
      _questions = [];
      _quizId = const Uuid().v4();
      _textController.text = widget.initialText ?? '';
      _titleController.text = widget.initialTitle ?? '';
      if (widget.initialText?.isNotEmpty == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _generateQuiz();
        });
      }
    }
  }

  Future<void> _generateQuiz() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      setState(() {
        _state = QuizState.error;
        _errorMessage = 'Please provide both a title and text.';
      });
      return;
    }

    final userModel = Provider.of<UserModel?>(context, listen: false);
    final usageService = Provider.of<UsageService?>(context, listen: false);
    if (userModel == null || usageService == null) return;

    if (!userModel.isPro) {
      final canGenerate = await usageService.canPerformAction('quizzes');
      if (!canGenerate) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const UpgradeDialog(featureName: 'quizzes'),
          );
        }
        return;
      }
    }

    setState(() {
      _state = QuizState.loading;
      _loadingMessage = 'Generating quiz...';
      _resetQuizState();
    });

    try {
      final folderId = await _aiService.generateAndStoreOutputs(
        text: _textController.text,
        title: _titleController.text,
        requestedOutputs: ['quiz'],
        userId: userModel.uid,
        localDb: _localDbService,
        onProgress: (message) {
          setState(() {
            _loadingMessage = message;
          });
        },
      );

      if (!userModel.isPro) {
        await usageService.recordAction('quizzes');
      }

      final content = await _localDbService.getFolderContents(folderId);
      final quizId =
          content.firstWhere((c) => c.contentType == 'quiz').contentId;
      final quiz = await _localDbService.getQuiz(quizId);

      if (quiz != null && quiz.questions.isNotEmpty) {
        setState(() {
          _questions = quiz.questions;
          _quizId = quiz.id;
          _state = QuizState.inProgress;
        });
      } else {
        throw Exception('AI service returned an empty quiz.');
      }
    } catch (e) {
      setState(() {
        _state = QuizState.error;
        _errorMessage = 'Error generating quiz: $e';
      });
    }
  }

  Future<void> _saveInProgress() async {
    if (_questions.isEmpty ||
        _titleController.text.isEmpty ||
        _quizId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cannot save an empty quiz."),
        ));
      }
      return;
    }

    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) return;

    final quizToSave = LocalQuiz(
      id: _quizId!,
      userId: user.uid,
      title: _titleController.text,
      questions: _questions,
      timestamp: DateTime.now(),
      scores: widget.quiz?.scores ?? [],
    );

    try {
      await _localDbService.saveQuiz(quizToSave);
      if (mounted) {
        Provider.of<QuizViewModel>(context, listen: false).refresh();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quiz progress saved!'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving progress: $e'),
        ));
      }
    }
  }

  Future<void> _saveFinalScoreAndExit() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    final quizViewModel = Provider.of<QuizViewModel>(context, listen: false);
    if (user == null || _quizId == null) return;

    final percentageScore =
        _questions.isNotEmpty ? (_score / _questions.length) * 100.0 : 0.0;

    var quizToSave = await _localDbService.getQuiz(_quizId!);

    if (quizToSave != null) {
      quizToSave.scores.add(percentageScore);
    } else {
      quizToSave = LocalQuiz(
        id: _quizId!,
        userId: user.uid,
        title: _titleController.text,
        questions: _questions,
        timestamp: DateTime.now(),
        scores: [percentageScore],
      );
    }

    try {
      await _localDbService.saveQuiz(quizToSave);
      quizViewModel.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Final score saved!'),
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving final score: $e'),
        ));
      }
    }
  }

  void _resetQuizState() {
    setState(() {
      _state = QuizState.inProgress;
      _score = 0;
    });
  }

  void _retry() {
    setState(() {
      _state = QuizState.creation;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(widget.quiz == null ? 'Create Quiz' : 'Take Quiz',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1A237E)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_state == QuizState.inProgress)
              IconButton(
                icon: const Icon(Icons.save_alt_outlined,
                    color: Color(0xFF1A237E)),
                onPressed: _saveInProgress,
                tooltip: 'Save Progress',
              )
          ],
        ),
        body: Stack(
          children: [
            // Animated Gradient Background
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
                            const Color(0xFFE8EAF6), // Indigo 50
                            Color.lerp(const Color(0xFFE8EAF6),
                                const Color(0xFFC5CAE9), value)!, // Indigo 100
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
      case QuizState.loading:
        return _buildLoadingState();
      case QuizState.error:
        return _buildErrorState();
      case QuizState.inProgress:
        return _buildQuizInterface();
      case QuizState.finished:
        return _buildResultScreen();
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
            ),
          ),
          const SizedBox(height: 32),
          Text(_loadingMessage,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E))),
          const SizedBox(height: 16),
          Text(
            "Our AI is crafting challenging questions...",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildGlassContainer(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text('Oops! Something went wrong.',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey[700])),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
          Text('Create a New Quiz',
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E)))
              .animate()
              .fadeIn()
              .slideY(begin: -0.2),
          const SizedBox(height: 32),
          _buildGlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz Title',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g., History Midterm Review',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Text to Generate From',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Paste your notes or article here.',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
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
                onPressed: _generateQuiz,
                icon: const Icon(Icons.psychology_alt_outlined),
                label: const Text('Generate Quiz',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF1A237E).withValues(alpha: 0.5),
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

  Widget _buildQuizInterface() {
    return QuizView(
      title: _titleController.text,
      questions: _questions,
      showSaveButton: false,
      onFinish: () {
        setState(() {
          _state = QuizState.finished;
        });
      },
      onAnswer: (isCorrect) {
        if (isCorrect) {
          setState(() {
            _score++;
          });
        }
      },
    );
  }

  Widget _buildResultScreen() {
    final percentage =
        _questions.isNotEmpty ? (_score / _questions.length) * 100 : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: _buildGlassContainer(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded,
                      size: 80, color: Colors.amber)
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(),
              const SizedBox(height: 24),
              Text('Quiz Results',
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 8),
              Text('Your Score: $_score out of ${_questions.length}',
                  style:
                      GoogleFonts.inter(fontSize: 18, color: Colors.grey[700])),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveFinalScoreAndExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save & Exit',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _resetQuizState,
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Retry Quiz',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E))),
                ),
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
          padding: padding ?? const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
