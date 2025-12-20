import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/user_model.dart';
import '../../models/local_quiz.dart';
import '../../models/local_quiz_question.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/local_database_service.dart';
import '../../services/usage_service.dart';
import '../../view_models/quiz_view_model.dart';
import '../widgets/upgrade_dialog.dart';

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

  late List<LocalQuizQuestion> _questions;
  bool _isLoading = false;
  bool _isQuizFinished = false;
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _answerWasSelected = false;
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
    } else {
      _questions = [];
      _quizId = const Uuid().v4();
      _textController.text = widget.initialText ?? '';
      _titleController.text = widget.initialTitle ?? '';
      // If there is initial text, generate the quiz immediately
      if (widget.initialText != null && widget.initialText!.isNotEmpty) {
        // Use WidgetsBinding to ensure context is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _generateQuiz();
          }
        });
      }
    }
  }

  Future<void> _generateQuiz() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please provide both a title and text to generate a quiz.')),
      );
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
      _isLoading = true;
      _resetQuizState();
    });

    try {
      // CRITICAL FIX: Call the new generateQuizFromText method
      final quiz = await _aiService.generateQuizFromText(
        _textController.text,
        _titleController.text,
        userModel.uid,
      );
      if (!userModel.isPro) {
        await usageService.recordAction('quizzes');
      }

      setState(() {
        _questions = quiz.questions
            .map((q) => LocalQuizQuestion(
                  question: q.question,
                  options: q.options,
                  correctAnswer: q.correctAnswer,
                ))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ... (All other methods remain the same: _getTileColor, _getTileIcon, etc.)
  Color _getTileColor(int index, ThemeData theme) {
    if (!_answerWasSelected) {
      return theme.cardColor;
    }
    final question = _questions[_currentQuestionIndex];
    final bool isCorrect = question.options[index] == question.correctAnswer;
    if (isCorrect) {
      return Colors.green.shade100;
    }
    if (index == _selectedAnswerIndex && !isCorrect) {
      return Colors.red.shade100;
    }
    return theme.cardColor;
  }

  Icon _getTileIcon(int index, ThemeData theme) {
    if (!_answerWasSelected) {
      return Icon(Icons.radio_button_unchecked, color: theme.disabledColor);
    }
    final question = _questions[_currentQuestionIndex];
    final bool isCorrect = question.options[index] == question.correctAnswer;

    if (isCorrect) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (index == _selectedAnswerIndex && !isCorrect) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    return Icon(Icons.radio_button_unchecked, color: theme.disabledColor);
  }

  Future<void> _saveInProgress() async {
    if (_questions.isEmpty ||
        _titleController.text.isEmpty ||
        _quizId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cannot save an empty quiz."),
        backgroundColor: Colors.orange,
      ));
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
      Provider.of<QuizViewModel>(context, listen: false).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quiz progress saved!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving progress: $e'),
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving final score: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _onAnswerSelected(int index) {
    if (_answerWasSelected) return;

    setState(() {
      _selectedAnswerIndex = index;
      _answerWasSelected = true;
      final question = _questions[_currentQuestionIndex];
      if (question.options[index] == question.correctAnswer) {
        _score++;
      }
    });
  }

  void _handleNextQuestion() {
    if (!_answerWasSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer.')),
      );
      return;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answerWasSelected = false;
      });
    } else {
      _onQuizFinished();
    }
  }

  void _onQuizFinished() {
    setState(() {
      _isQuizFinished = true;
    });
  }

  void _resetQuizState() {
    setState(() {
      _isQuizFinished = false;
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _answerWasSelected = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuizInProgress = _questions.isNotEmpty && !_isQuizFinished;

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
            if (isQuizInProgress)
              IconButton(
                icon:
                    Icon(Icons.save_alt_outlined, color: theme.iconTheme.color),
                onPressed: _saveInProgress,
                tooltip: 'Save Progress',
              )
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
    if (_isQuizFinished) {
      return _buildResultScreen(theme);
    } else if (_questions.isNotEmpty) {
      return _buildQuizInterface(theme);
    } else {
      return _buildCreationForm(theme);
    }
  }

  Widget _buildCreationForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text('Create Quiz', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quiz Title', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter quiz title',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Text', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter text to generate quiz',
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
                onPressed: _isLoading ? null : _generateQuiz,
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
                    : const Icon(Icons.psychology_alt_outlined),
                label: Text(
                  _isLoading ? 'Generating Quiz...' : 'Generate Quiz',
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

  Widget _buildQuizInterface(ThemeData theme) {
    final question = _questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(_titleController.text,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Question ${_currentQuestionIndex + 1}/${_questions.length}',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Text(
            question.question,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: _answerWasSelected ? 4 : 2,
                  color: _getTileColor(index, theme),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedAnswerIndex == index
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    title: Text(question.options[index],
                        style: theme.textTheme.bodyLarge),
                    leading: _getTileIcon(index, theme),
                    onTap: () => _onAnswerSelected(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _answerWasSelected ? _handleNextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentQuestionIndex < _questions.length - 1
                    ? 'Next Question'
                    : 'Finish Quiz',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultScreen(ThemeData theme) {
    final percentage =
        _questions.isNotEmpty ? (_score / _questions.length) * 100 : 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Quiz Results', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Your Score: $_score out of ${_questions.length}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveFinalScoreAndExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Save & Exit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetQuizState,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.onSurface),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Retry Quiz',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
