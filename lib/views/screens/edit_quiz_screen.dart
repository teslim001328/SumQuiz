import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/models/editable_content.dart';
import 'package:sumquiz/models/quiz_question.dart';
import 'package:sumquiz/services/auth_service.dart';
import 'package:sumquiz/services/firestore_service.dart';

class EditQuizScreen extends StatefulWidget {
  final EditableContent content;

  const EditQuizScreen({super.key, required this.content});

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  late TextEditingController _titleController;
  late List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.content.title);
    _questions = List.from(widget.content.questions ?? []);
  }

  Future<void> _save() async {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to save.')));
      return;
    }

    try {
      await firestoreService.updateQuiz(
        user.uid,
        widget.content.id,
        _titleController.text,
        _questions,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz saved successfully')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving quiz: $e')));
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuizQuestion(
        question: 'New Question',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswer: 'Option 1',
      ));
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Edit Quiz',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _save,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated Background
          Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              CustomEffect(
                duration: 12.seconds,
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1A237E), // Indigo 900
                          Color.lerp(
                              const Color(0xFF1A237E),
                              const Color(0xFF311B92),
                              value)!, // Deep Purple 900
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  _buildGlassSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quiz Title',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white70)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _questions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _QuestionEditor(
                          index: index,
                          question: _questions[index],
                          onUpdate: (q) {
                            setState(() {
                              _questions[index] = q;
                            });
                          },
                          onDelete: () {
                            setState(() {
                              _questions.removeAt(index);
                            });
                          },
                        ).animate(delay: (100 * index).ms).fadeIn().slideX();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _addQuestion,
          icon: const Icon(Icons.add),
          label: const Text('Add New Question'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSection({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _QuestionEditor extends StatefulWidget {
  final int index;
  final QuizQuestion question;
  final Function(QuizQuestion) onUpdate;
  final VoidCallback onDelete;

  const _QuestionEditor({
    required this.index,
    required this.question,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(widget.question.question,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('Question ${widget.index + 1}',
                      style: GoogleFonts.inter(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent.withValues(alpha: 0.8)),
                        onPressed: widget.onDelete,
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                ),
                if (_isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        // Question Text Input
                        _buildGlassInput(
                          initialValue: widget.question.question,
                          label: 'Question Text',
                          onChanged: (val) {
                            widget.onUpdate(QuizQuestion(
                              question: val,
                              options: widget.question.options,
                              correctAnswer: widget.question.correctAnswer,
                            ));
                          },
                        ),
                        const SizedBox(height: 16),
                        // Options Inputs
                        ...List.generate(4, (optIndex) {
                          final isCorrect =
                              widget.question.options.length > optIndex &&
                                  widget.question.correctAnswer ==
                                      widget.question.options[optIndex];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isCorrect
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isCorrect
                                        ? Colors.greenAccent
                                        : Colors.white54,
                                  ),
                                  onPressed: () {
                                    if (widget.question.options.length >
                                        optIndex) {
                                      widget.onUpdate(QuizQuestion(
                                        question: widget.question.question,
                                        options: widget.question.options,
                                        correctAnswer:
                                            widget.question.options[optIndex],
                                      ));
                                    }
                                  },
                                ),
                                Expanded(
                                  child: _buildGlassInput(
                                    initialValue:
                                        widget.question.options.length >
                                                optIndex
                                            ? widget.question.options[optIndex]
                                            : '',
                                    label: 'Option ${optIndex + 1}',
                                    onChanged: (val) {
                                      final newOptions = List<String>.from(
                                          widget.question.options);
                                      if (newOptions.length > optIndex) {
                                        newOptions[optIndex] = val;
                                      }
                                      // Also update correct answer if it matched previously
                                      String newCorrect =
                                          widget.question.correctAnswer;
                                      if (isCorrect) {
                                        newCorrect = val;
                                      }
                                      widget.onUpdate(QuizQuestion(
                                        question: widget.question.question,
                                        options: newOptions,
                                        correctAnswer: newCorrect,
                                      ));
                                    },
                                    isCorrect: isCorrect,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            )),
      ),
    );
  }

  Widget _buildGlassInput({
    required String initialValue,
    required String label,
    required Function(String) onChanged,
    bool isCorrect = false,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: GoogleFonts.inter(
          color: isCorrect ? Colors.greenAccent : Colors.white,
          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isCorrect
                  ? Colors.greenAccent.withValues(alpha: 0.5)
                  : Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isCorrect
                  ? Colors.greenAccent.withValues(alpha: 0.5)
                  : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isCorrect ? Colors.greenAccent : Colors.white70),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }
}
