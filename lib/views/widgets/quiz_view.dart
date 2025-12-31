import 'package:flutter/material.dart';
import '../../models/local_quiz_question.dart';

class QuizView extends StatefulWidget {
  final String title;
  final List<LocalQuizQuestion> questions;
  final VoidCallback? onFinish;
  final bool showSaveButton;
  final VoidCallback? onSaveProgress;
  final Function(bool isCorrect)? onAnswer;

  const QuizView({
    super.key,
    required this.title,
    required this.questions,
    this.onFinish,
    this.showSaveButton = false,
    this.onSaveProgress,
    this.onAnswer,
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _answerWasSelected = false;

  void _onAnswerSelected(int index) {
    if (_answerWasSelected) return;

    setState(() {
      _selectedAnswerIndex = index;
      _answerWasSelected = true;
    });

    if (widget.onAnswer != null) {
      final question = widget.questions[_currentQuestionIndex];
      final isCorrect = question.options[index] == question.correctAnswer;
      widget.onAnswer!(isCorrect);
    }
  }

  void _handleNextQuestion() {
    if (!_answerWasSelected) return;

    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answerWasSelected = false;
      });
    } else {
      // Quiz Finished
      widget.onFinish?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(child: Text("No questions available."));
    }

    final question = widget.questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                        'Question ${_currentQuestionIndex + 1}/${widget.questions.length}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (widget.showSaveButton && widget.onSaveProgress != null)
                IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  onPressed: widget.onSaveProgress,
                  tooltip: 'Save Progress',
                )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            question.question,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: _answerWasSelected ? 4 : 2,
                  color: _getTileColor(index, question),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedAnswerIndex == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    title: Text(question.options[index],
                        style: Theme.of(context).textTheme.bodyLarge),
                    leading: _getTileIcon(index, question),
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
              child: Text(
                _currentQuestionIndex < widget.questions.length - 1
                    ? 'Next Question'
                    : 'Finish Quiz',
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color? _getTileColor(int index, LocalQuizQuestion question) {
    if (!_answerWasSelected) return Theme.of(context).cardColor;
    if (question.options[index] == question.correctAnswer) {
      return Colors.green.shade50;
    }
    if (index == _selectedAnswerIndex) return Colors.red.shade50;
    return Theme.of(context).cardColor;
  }

  Widget _getTileIcon(int index, LocalQuizQuestion question) {
    if (!_answerWasSelected) {
      return Icon(Icons.circle_outlined,
          color: Theme.of(context).disabledColor);
    }
    if (question.options[index] == question.correctAnswer) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (index == _selectedAnswerIndex) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    return Icon(Icons.circle_outlined, color: Theme.of(context).disabledColor);
  }
}
