import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/local_quiz.dart';
import '../../models/local_quiz_question.dart';
import '../../models/user_model.dart';
import '../../services/local_database_service.dart';

// Suppress deprecated Radio warnings (RadioGroup has known issues as of Flutter 3.38+)
// ignore_for_file: deprecated_member_use

class EditQuizScreen extends StatefulWidget {
  final LocalQuiz quiz;

  const EditQuizScreen({super.key, required this.quiz});

  @override
  EditQuizScreenState createState() => EditQuizScreenState();
}

class EditQuizScreenState extends State<EditQuizScreen> {
  late TextEditingController _titleController;
  late List<TextEditingController> _questionControllers;
  late List<List<TextEditingController>> _optionControllers;
  late List<int?> _correctAnswerIndices;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz.title);

    // Parse correctAnswer from String to int (safe fallback to 0)
    _correctAnswerIndices = widget.quiz.questions
        .map((q) => int.tryParse(q.correctAnswer) ?? 0)
        .toList();

    _questionControllers = widget.quiz.questions
        .map((q) => TextEditingController(text: q.question))
        .toList();

    _optionControllers = widget.quiz.questions
        .map((q) => q.options.map((opt) => TextEditingController(text: opt)).toList())
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    for (var controllers in _optionControllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
      _optionControllers.add([TextEditingController(), TextEditingController()]);
      _correctAnswerIndices.add(0);
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questionControllers[index].dispose();
      for (var controller in _optionControllers[index]) {
        controller.dispose();
      }
      _questionControllers.removeAt(index);
      _optionControllers.removeAt(index);
      _correctAnswerIndices.removeAt(index);
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      _optionControllers[questionIndex].add(TextEditingController());
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      _optionControllers[questionIndex][optionIndex].dispose();
      _optionControllers[questionIndex].removeAt(optionIndex);

      if (_correctAnswerIndices[questionIndex] == optionIndex) {
        _correctAnswerIndices[questionIndex] = 0;
      } else if (_correctAnswerIndices[questionIndex] != null &&
          _correctAnswerIndices[questionIndex]! > optionIndex) {
        _correctAnswerIndices[questionIndex] =
            _correctAnswerIndices[questionIndex]! - 1;
      }
    });
  }

  void _saveChanges() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Not logged in.')),
        );
      }
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz title cannot be empty.')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    final db = LocalDatabaseService();
    final List<LocalQuizQuestion> updatedQuestions = [];

    for (int i = 0; i < _questionControllers.length; i++) {
      final questionText = _questionControllers[i].text.trim();
      if (questionText.isEmpty) continue;

      final options = _optionControllers[i]
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (options.length < 2) continue;

      int correctIndex = (_correctAnswerIndices[i] ?? 0).clamp(0, options.length - 1);

      updatedQuestions.add(
        LocalQuizQuestion(
          question: questionText,
          options: options,
          correctAnswer: correctIndex.toString(),
        ),
      );
    }

    if (updatedQuestions.isEmpty) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one valid question with 2+ options.')),
        );
      }
      return;
    }

    final updatedQuiz = LocalQuiz(
      id: widget.quiz.id,
      title: _titleController.text.trim(),
      questions: updatedQuestions,
      timestamp: DateTime.now(), // Fixed: DateTime instead of String
      userId: user.uid,
      isSynced: false,
    );

    await db.saveQuiz(updatedQuiz);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz saved successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Quiz'),
        actions: [
          IconButton(
            icon: _isSaving
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Quiz Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  _buildQuestionsList(theme),
                ],
              ),
            ),
          ),
          _buildAddQuestionButton(theme),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questionControllers.length,
      itemBuilder: (context, qIndex) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${qIndex + 1}', style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                      onPressed: () => _removeQuestion(qIndex),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _questionControllers[qIndex],
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 16),
                Text('Options', style: theme.textTheme.titleSmall),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _optionControllers[qIndex].length,
                  itemBuilder: (context, oIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: oIndex,
                            groupValue: _correctAnswerIndices[qIndex],
                            onChanged: (int? value) {
                              setState(() {
                                _correctAnswerIndices[qIndex] = value;
                              });
                            },
                            activeColor: theme.colorScheme.primary,
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _optionControllers[qIndex][oIndex],
                              decoration: InputDecoration(
                                labelText: 'Option ${oIndex + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: _optionControllers[qIndex].length > 2
                                ? () => _removeOption(qIndex, oIndex)
                                : null,
                            color: theme.colorScheme.error.withValues(
                              alpha: _optionControllers[qIndex].length > 2 ? 1.0 : 0.3,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                  onPressed: () => _addOption(qIndex),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddQuestionButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add New Question'),
        onPressed: _addQuestion,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}