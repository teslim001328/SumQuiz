import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/summary_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/usage_service.dart';
import '../widgets/upgrade_dialog.dart';
import 'quiz_screen.dart';
import '../../models/local_quiz.dart';
import '../../models/local_quiz_question.dart';

enum SummaryState { initial, loading, error, success }

class SummaryScreen extends StatefulWidget {
  final Summary? summary;

  const SummaryScreen({super.key, this.summary});

  @override
  SummaryScreenState createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _pdfFileName;
  Uint8List? _pdfBytes;
  SummaryState _state = SummaryState.initial;
  String _summaryContent = '';
  String _summaryTitle = '';
  List<String> _summaryTags = [];
  String _errorMessage = '';
  bool _isGeneratingQuiz = false;

  late final FirestoreService _firestoreService;
  late final EnhancedAIService _aiService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _aiService = EnhancedAIService();
    if (widget.summary != null) {
      _summaryContent = widget.summary!.content;
      _summaryTitle = widget.summary!.title;
      _summaryTags = widget.summary!.tags;
      _state = SummaryState.success;
    }
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _pdfBytes = result.files.single.bytes;
          _pdfFileName = result.files.single.name;
        });
      }
    } catch (e, s) {
      developer.log('Error picking or reading PDF',
          name: 'my_app.summary', error: e, stackTrace: s);
      setState(() {
        _state = SummaryState.error;
        _errorMessage = "Error picking or reading PDF: $e";
      });
    }
  }

  void _generateSummary() async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    final usageService = Provider.of<UsageService?>(context, listen: false);
    if (userModel == null || usageService == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User not available. Please log in again.')),
      );
      return;
    }

    if (!userModel.isPro) {
      final canGenerate = await usageService.canPerformAction('summaries');
      if (!canGenerate) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const UpgradeDialog(featureName: 'summaries'),
          );
        }
        return;
      }
    }

    setState(() => _state = SummaryState.loading);

    try {
      final summaryJsonString = await _aiService.generateSummary(
        _textController.text,
        pdfBytes: _pdfBytes,
      );
      final summaryData =
          json.decode(summaryJsonString) as Map<String, dynamic>;

      if (summaryData.containsKey('error')) {
        setState(() {
          _state = SummaryState.error;
          _errorMessage = summaryData['error'];
        });
      } else {
        if (!userModel.isPro) {
          await usageService.recordAction('summaries');
        }
        setState(() {
          _summaryTitle = summaryData['title'] ?? 'Summary';
          _summaryContent = summaryData['content'] ?? '';
          _summaryTags = List<String>.from(summaryData['tags'] ?? []);
          _state = SummaryState.success;
        });
      }
    } catch (e, s) {
      developer.log(
        'An unexpected error occurred during summary generation',
        name: 'my_app.summary',
        error: e,
        stackTrace: s,
      );
      setState(() {
        _state = SummaryState.error;
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    }
  }

  void _retry() {
    setState(() {
      _state = SummaryState.initial;
      _summaryContent = '';
      _summaryTitle = '';
      _summaryTags = [];
      _errorMessage = '';
    });
  }

  void _copySummary() {
    Clipboard.setData(ClipboardData(text: _summaryContent));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary content copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveToLibrary() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final summaryToSave = Summary(
          id: '',
          userId: user.uid,
          title: _summaryTitle,
          content: _summaryContent,
          tags: _summaryTags,
          timestamp: Timestamp.now(),
        );
        await _firestoreService.addSummary(user.uid, summaryToSave);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary saved to library!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e, s) {
        developer.log('Error saving summary',
            name: 'my_app.summary', error: e, stackTrace: s);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving summary.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateQuiz() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isGeneratingQuiz = true);

    try {
      final summary = Summary(
        id: '',
        userId: user.uid,
        title: _summaryTitle,
        content: _summaryContent,
        tags: _summaryTags,
        timestamp: Timestamp.now(),
      );
      final quiz = await _aiService.generateQuizFromSummary(summary);

      final localQuiz = LocalQuiz(
        id: const Uuid().v4(),
        userId: user.uid,
        title: quiz.title,
        questions: quiz.questions
            .map((q) => LocalQuizQuestion(
                  question: q.question,
                  options: q.options,
                  correctAnswer: q.correctAnswer,
                ))
            .toList(),
        timestamp: DateTime.now(),
        scores: [],
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizScreen(quiz: localQuiz)),
        );
      }
    } catch (e, s) {
      developer.log('Error generating quiz',
          name: 'my_app.summary', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error generating quiz.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingQuiz = false);
    }
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
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: _buildBody(theme),
            ),
          ),
        ));
  }

  Widget _buildBody(ThemeData theme) {
    switch (_state) {
      case SummaryState.error:
        return _buildErrorState(theme);
      case SummaryState.success:
        return _buildSuccessState(theme);
      default:
        return _buildInitialState(theme);
    }
  }

  Widget _buildInitialState(ThemeData theme) {
    bool canGenerate = _textController.text.isNotEmpty || _pdfFileName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Paste text or upload a file to get started.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        TextField(
          controller: _textController,
          maxLines: 12,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardColor,
            hintText: 'Paste your text here...',
            hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
          onChanged: (text) => setState(() {}),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: Icon(Icons.upload_file, color: theme.iconTheme.color),
          label: Text(_pdfFileName ?? 'Upload PDF',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          onPressed: _pickPdf,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: theme.colorScheme.onSurface.withAlpha(138)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_pdfFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _pdfBytes = null;
                  _pdfFileName = null;
                }),
                child: const Text('Clear PDF',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: canGenerate && _state != SummaryState.loading
              ? _generateSummary
              : null,
          icon: _state == SummaryState.loading
              ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.summarize_outlined),
          label: _state == SummaryState.loading
              ? const Text('Summarizing...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              : const Text('Generate Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text('Oops! Something went wrong.',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_errorMessage,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: _retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    final bool isViewingSaved = widget.summary != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(77),
                  blurRadius: 15,
                  spreadRadius: 2)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_summaryTitle,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 16),
              if (_summaryTags.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _summaryTags
                      .map((tag) => Chip(
                            label: Text(tag,
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface)),
                            backgroundColor:
                                theme.colorScheme.surface.withAlpha(128),
                          ))
                      .toList(),
                ),
              if (_summaryTags.isNotEmpty) const SizedBox(height: 16),
              Text(_summaryContent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(222))),
            ],
          ),
        ),
        const SizedBox(height: 30),
        if (!isViewingSaved)
          Row(
            children: [
              Expanded(child: _buildActionButton(theme, 'Copy', _copySummary)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildActionButton(theme, 'Save', _saveToLibrary)),
            ],
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isGeneratingQuiz ? null : _generateQuiz,
          icon: _isGeneratingQuiz
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
          label: _isGeneratingQuiz
              ? const Text(
                  "Generating Quiz...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )
              : const Text(
                  "Generate Quiz",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 16),
        if (!isViewingSaved)
          Center(
            child: TextButton(
              onPressed: _retry,
              child: Text('Generate Another Summary',
                  style: theme.textTheme.bodySmall),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
      ThemeData theme, String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.cardColor,
        foregroundColor: theme.colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
