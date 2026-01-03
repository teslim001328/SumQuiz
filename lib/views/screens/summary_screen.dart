import 'dart:ui';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/user_model.dart';
import '../../services/local_database_service.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/usage_service.dart';
import '../widgets/upgrade_dialog.dart';
import '../widgets/summary_view.dart';

enum ScreenState { initial, loading, error, success }

class SummaryScreen extends StatefulWidget {
  final LocalSummary? summary;

  const SummaryScreen({super.key, this.summary});

  @override
  SummaryScreenState createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _pdfFileName;
  // Uint8List? _pdfBytes; // Removed unused field
  ScreenState _state = ScreenState.initial;
  String _summaryContent = '';
  String _summaryTitle = '';
  List<String> _summaryTags = [];
  String _errorMessage = '';
  String _loadingMessage = 'Generating Summary...';
  bool _isGeneratingQuiz = false;

  late final EnhancedAIService _aiService;
  late final LocalDatabaseService _localDbService;

  @override
  void initState() {
    super.initState();
    _aiService = EnhancedAIService();
    _localDbService = LocalDatabaseService();
    _localDbService.init();
    if (widget.summary != null) {
      _summaryContent = widget.summary!.content;
      _summaryTitle = widget.summary!.title;
      _summaryTags = widget.summary!.tags;
      _state = ScreenState.success;
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
          // _pdfBytes = result.files.single.bytes; // Removed unused assignment
          _pdfFileName = result.files.single.name;
        });
      }
    } catch (e, s) {
      developer.log('Error picking or reading PDF',
          name: 'summary.screen', error: e, stackTrace: s);
      setState(() {
        _state = ScreenState.error;
        _errorMessage = "Error picking or reading PDF: $e";
      });
    }
  }

  void _generateSummary() async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    final usageService = Provider.of<UsageService?>(context, listen: false);
    if (userModel == null || usageService == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User not available. Please log in again.')));
      return;
    }

    if (!userModel.isPro &&
        !(await usageService.canPerformAction('summaries'))) {
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) =>
                const UpgradeDialog(featureName: 'summaries'));
      }
      return;
    }

    setState(() {
      _state = ScreenState.loading;
      _loadingMessage = 'Generating summary...';
    });

    try {
      final folderId = await _aiService.generateAndStoreOutputs(
        text: _textController.text,
        title: _summaryTitle.isNotEmpty ? _summaryTitle : 'Summary',
        requestedOutputs: ['summary'],
        userId: userModel.uid,
        localDb: _localDbService,
        onProgress: (message) {
          setState(() {
            _loadingMessage = message;
          });
        },
      );

      final content = await _localDbService.getFolderContents(folderId);
      final summaryId =
          content.firstWhere((c) => c.contentType == 'summary').contentId;
      final summary = await _localDbService.getSummary(summaryId);

      if (summary != null) {
        if (!userModel.isPro) await usageService.recordAction('summaries');
        setState(() {
          _summaryTitle = summary.title;
          _summaryContent = summary.content;
          _summaryTags = summary.tags;
          _state = ScreenState.success;
        });
      } else {
        throw Exception('Failed to retrieve the generated summary.');
      }
    } catch (e, s) {
      developer.log('An unexpected error occurred during summary generation',
          name: 'summary.screen', error: e, stackTrace: s);
      setState(() {
        _state = ScreenState.error;
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    }
  }

  void _retry() => setState(() {
        _state = ScreenState.initial;
        _summaryContent = _summaryTitle = _errorMessage = '';
        _summaryTags = [];
        _textController.clear();
        // _pdfBytes = null; // Removed unused field
        _pdfFileName = null;
      });

  void _copySummary() {
    Clipboard.setData(ClipboardData(text: _summaryContent));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary content copied to clipboard!')));
  }

  void _saveToLibrary() async {
    final user = context.read<UserModel?>();
    if (user == null) return;

    try {
      final summaryToSave = LocalSummary(
        id: const Uuid().v4(),
        userId: user.uid,
        title: _summaryTitle,
        content: _summaryContent,
        tags: _summaryTags,
        timestamp: DateTime.now(),
        isSynced: false,
      );
      await _localDbService.saveSummary(summaryToSave);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary saved to library!')));
    } catch (e, s) {
      developer.log('Error saving summary',
          name: 'summary.screen', error: e, stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error saving summary.')));
    }
  }

  Future<void> _generateQuiz() async {
    setState(() => _isGeneratingQuiz = true);
    try {
      final user = context.read<UserModel?>();
      if (user == null || _summaryContent.isEmpty) return;

      if (!mounted) return;
      context.push('/quiz', extra: {
        'initialText': _summaryContent,
        'initialTitle': _summaryTitle
      });
    } catch (e, s) {
      developer.log('Error navigating to quiz generation',
          name: 'summary.screen', error: e, stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start quiz generation.')));
    } finally {
      if (mounted) setState(() => _isGeneratingQuiz = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
            widget.summary == null ? 'Generate Summary' : 'Summary Details',
            style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: BackButton(color: theme.colorScheme.onSurface),
      ),
      body: Stack(
        children: [
          // Simple background
          Container(color: theme.colorScheme.surface),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: _buildBody(theme),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_state) {
      case ScreenState.loading:
        return _buildLoadingState(theme);
      case ScreenState.error:
        return _buildErrorState(theme);
      case ScreenState.success:
        return _buildSuccessState();
      default:
        return _buildInitialState(theme);
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 32),
          Text(_loadingMessage,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    final canGenerate = _textController.text.isNotEmpty || _pdfFileName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Summarize Content',
          style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ).animate().fadeIn().slideY(begin: -0.2),
        const SizedBox(height: 12),
        Text(
          'Paste text or upload a PDF to generate a comprehensive summary.',
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2),
        const SizedBox(height: 48),
        Container(
          // Document-like container
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              TextField(
                controller: _textController,
                maxLines: null,
                minLines: 15,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Paste your text here...',
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (text) => setState(() {}),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.upload_file,
                          color: _pdfFileName != null
                              ? Colors.green
                              : theme.colorScheme.primary),
                      label: Text(
                        _pdfFileName ?? 'Upload PDF',
                        style: TextStyle(
                            color: _pdfFileName != null
                                ? Colors.green
                                : theme.colorScheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        side: BorderSide(
                            color: _pdfFileName != null
                                ? Colors.green
                                : theme.dividerColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _pickPdf,
                    ),
                  ),
                  if (_pdfFileName != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                        onPressed: () => setState(() => _pdfFileName = null),
                        icon: const Icon(Icons.close, color: Colors.redAccent))
                  ]
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 32),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: canGenerate ? _generateSummary : null,
            icon: const Icon(Icons.summarize_outlined),
            label: const Text('Generate Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              disabledBackgroundColor: theme.disabledColor,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).scale(),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: _buildGlassContainer(
        theme: theme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.orangeAccent, size: 64),
            const SizedBox(height: 16),
            Text('Oops! Something went wrong.',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSuccessState() {
    final isViewingSaved = widget.summary != null;
    return SummaryView(
      title: _summaryTitle,
      content: _summaryContent,
      tags: _summaryTags,
      onCopy: _copySummary,
      onSave: isViewingSaved ? null : _saveToLibrary,
      onGenerateQuiz: _isGeneratingQuiz ? null : _generateQuiz,
      showActions: !isViewingSaved,
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildGlassContainer(
      {required Widget child,
      EdgeInsetsGeometry? padding,
      required ThemeData theme}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}
