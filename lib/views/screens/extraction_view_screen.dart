import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/enhanced_ai_service.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/services/usage_service.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/views/widgets/upgrade_dialog.dart';

// Import the exception class
// part 'package:sumquiz/services/enhanced_ai_service.dart' show EnhancedAIServiceException;

class ExtractionViewScreen extends StatefulWidget {
  final String? initialText;

  const ExtractionViewScreen({super.key, this.initialText});

  @override
  State<ExtractionViewScreen> createState() => _ExtractionViewScreenState();
}

class _ExtractionViewScreenState extends State<ExtractionViewScreen> {
  late TextEditingController _textController;
  final TextEditingController _titleController = TextEditingController();
  OutputType _selectedOutputType = OutputType.summary;
  bool _generateSummary = true;
  bool _generateQuiz = false;
  bool _generateFlashcards = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    // Initialize checkboxes based on selected output type
    _updateCheckboxes();
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _selectOutputType(OutputType type) {
    setState(() {
      _selectedOutputType = type;
      _updateCheckboxes();
    });
  }

  void _updateCheckboxes() {
    switch (_selectedOutputType) {
      case OutputType.summary:
        _generateSummary = true;
        _generateQuiz = false;
        _generateFlashcards = false;
        break;
      case OutputType.quizzes:
        _generateSummary = false;
        _generateQuiz = true;
        _generateFlashcards = false;
        break;
      case OutputType.flashcards:
        _generateSummary = false;
        _generateQuiz = false;
        _generateFlashcards = true;
        break;
    }
  }

  void _toggleSummary() {
    setState(() {
      _generateSummary = !_generateSummary;
      if (_generateSummary) _selectedOutputType = OutputType.summary;
    });
  }

  void _toggleQuiz() {
    setState(() {
      _generateQuiz = !_generateQuiz;
      if (_generateQuiz) _selectedOutputType = OutputType.quizzes;
    });
  }

  void _toggleFlashcards() {
    setState(() {
      _generateFlashcards = !_generateFlashcards;
      if (_generateFlashcards) _selectedOutputType = OutputType.flashcards;
    });
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
      final aiService = context.read<EnhancedAIService>();
      final localDb = context.read<LocalDatabaseService>();
      final userId = user?.uid ?? 'unknown_user';

      final requestedOutputs = <String>[];
      if (_generateSummary) requestedOutputs.add('summary');
      if (_generateQuiz) requestedOutputs.add('quiz');
      if (_generateFlashcards) requestedOutputs.add('flashcards');

      // Show loading indicator with AI processing message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing with AI...')),
        );
      }

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
        // Clear the loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.go('/results-view/$folderId');
      }
    } on EnhancedAIServiceException catch (e) {
      // Handle specific AI service exceptions
      _showError('AI Processing Error: ${e.message}');
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extraction View'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTitleField(),
          _buildSelectionButtons(),
          _buildCheckboxOptions(),
          Expanded(
            child: _buildDocumentDisplayArea(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _handleGenerate,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_fix_high),
        label: const Text('Generate'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Title (Optional)',
          hintText: 'Enter a title for your content...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSelectionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildToggleButton(OutputType.summary, 'Summary'),
          const SizedBox(width: 8),
          _buildToggleButton(OutputType.quizzes, 'Quizzes'),
          const SizedBox(width: 8),
          _buildToggleButton(OutputType.flashcards, 'Flashcards'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(OutputType type, String label) {
    final bool isSelected = _selectedOutputType == type;
    final theme = Theme.of(context);

    return Expanded(
      child: ElevatedButton(
        onPressed: () => _selectOutputType(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          foregroundColor:
              isSelected ? Colors.white : theme.colorScheme.onSurface,
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check,
                size: 18,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Output Formats:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Summary'),
                value: _generateSummary,
                onChanged: (value) => _toggleSummary(),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Quizzes'),
                value: _generateQuiz,
                onChanged: (value) => _toggleQuiz(),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Flashcards'),
                value: _generateFlashcards,
                onChanged: (value) => _toggleFlashcards(),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentDisplayArea() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: null,
            decoration: const InputDecoration(
              hintText:
                  'Extracted text will appear here. You can edit it before generating.',
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

enum OutputType {
  summary,
  quizzes,
  flashcards,
}
