import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/ai_service.dart';
import 'package:myapp/services/local_database_service.dart';
import 'package:myapp/services/usage_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/views/widgets/upgrade_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExtractionScreen extends StatefulWidget {
  final String? initialText;

  const ExtractionScreen({super.key, this.initialText});

  @override
  State<ExtractionScreen> createState() => _ExtractionScreenState();
}

class _ExtractionScreenState extends State<ExtractionScreen> {
  late TextEditingController _textController;
  final TextEditingController _titleController = TextEditingController();

  bool _generateSummary = true;
  bool _generateQuiz = false;
  bool _generateFlashcards = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    if (_textController.text.trim().isEmpty) {
      _showError('Please enter or paste some content first.');
      return;
    }

    if (!_generateSummary && !_generateQuiz && !_generateFlashcards) {
      _showError('Please select at least one output format.');
      return;
    }

    // PRO & USAGE CHECKS
    final user = context.read<UserModel?>();
    final usageService = context.read<UsageService?>();

    if (user != null && !user.isPro && usageService != null) {
      if (_generateSummary &&
          !await usageService.canPerformAction('summaries')) {
        if (mounted) _showUpgradeDialog('Summaries');
        return;
      }
      if (_generateQuiz && !await usageService.canPerformAction('quizzes')) {
        if (mounted) _showUpgradeDialog('Quizzes');
        return;
      }
      if (_generateFlashcards &&
          !await usageService.canPerformAction('flashcards')) {
        if (mounted) _showUpgradeDialog('Flashcards');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final aiService = context.read<AIService>();
      final localDb = context.read<LocalDatabaseService>();
      final userId = user?.uid ?? 'unknown_user';

      final requestedOutputs = <String>[];
      if (_generateSummary) requestedOutputs.add('summary');
      if (_generateQuiz) requestedOutputs.add('quiz');
      if (_generateFlashcards) requestedOutputs.add('flashcards');

      final folderId = await aiService.generateOutputs(
        text: _textController.text,
        title: _titleController.text.isNotEmpty
            ? _titleController.text
            : 'New Creation',
        requestedOutputs: requestedOutputs,
        userId: userId,
        localDb: localDb,
      );

      // Record usage if successful
      if (user != null && !user.isPro && usageService != null) {
        if (_generateSummary) usageService.recordAction('summaries');
        if (_generateQuiz) usageService.recordAction('quizzes');
        if (_generateFlashcards) usageService.recordAction('flashcards');
      }

      if (mounted) {
        context.go('/results/$folderId');
      }
    } catch (e) {
      _showError('Generation failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUpgradeDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => UpgradeDialog(featureName: feature),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Configure'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _handleGenerate,
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Title Input
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Content Input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Paste your content here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Options
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        _buildCheckbox('Summary', _generateSummary,
                            (v) => setState(() => _generateSummary = v!)),
                        _buildCheckbox('Quiz', _generateQuiz,
                            (v) => setState(() => _generateQuiz = v!)),
                        _buildCheckbox('Flashcards', _generateFlashcards,
                            (v) => setState(() => _generateFlashcards = v!)),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGenerate,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Generate Content'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
      String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      value: value,
      onChanged: onChanged,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
