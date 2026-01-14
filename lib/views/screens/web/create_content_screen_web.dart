import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/theme/web_theme.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/services/content_extraction_service.dart';
import 'package:sumquiz/services/usage_service.dart';
import 'package:sumquiz/views/widgets/upgrade_dialog.dart';

class CreateContentScreenWeb extends StatefulWidget {
  const CreateContentScreenWeb({super.key});

  @override
  State<CreateContentScreenWeb> createState() => _CreateContentScreenWebState();
}

class _CreateContentScreenWebState extends State<CreateContentScreenWeb>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _linkController = TextEditingController();
  String? _fileName;
  Uint8List? _fileBytes;
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedInputType = 'text';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _resetInputs() {
    _textController.clear();
    _linkController.clear();
    setState(() {
      _fileName = null;
      _fileBytes = null;
      _errorMessage = '';
    });
  }

  bool _checkProAccess(String feature) {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null && !user.isPro) {
      showDialog(
        context: context,
        builder: (_) => UpgradeDialog(featureName: feature),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickFile(String type) async {
    if (!_checkProAccess(type == 'pdf' ? 'PDF Upload' : 'Image Scan')) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type == 'pdf' ? FileType.custom : FileType.image,
        allowedExtensions: type == 'pdf' ? ['pdf'] : ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileName = result.files.single.name;
          _fileBytes = result.files.single.bytes;
          _selectedInputType = type;
          _textController.clear();
          _linkController.clear();
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error picking file: $e');
    }
  }

  Future<void> _processAndNavigate() async {
    if (_isLoading) return;

    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) {
      setState(
          () => _errorMessage = 'You must be logged in to create content.');
      return;
    }

    final usageService = UsageService();
    final canGenerate = await usageService.canGenerateDeck(user.uid);

    if (!mounted) return;
    if (!canGenerate) {
      showDialog(
        context: context,
        builder: (_) => const UpgradeDialog(featureName: 'Daily Limit'),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final extractionService =
          Provider.of<ContentExtractionService>(context, listen: false);
      String extractedText = '';

      switch (_selectedInputType) {
        case 'text':
          if (_textController.text.trim().isEmpty) {
            throw Exception('Text field cannot be empty.');
          }
          extractedText = _textController.text;
          break;
        case 'link':
          if (_linkController.text.trim().isEmpty) {
            throw Exception('URL field cannot be empty.');
          }
          if (!_checkProAccess('Web Link')) {
            setState(() => _isLoading = false);
            return;
          }
          extractedText = await extractionService.extractContent(
              type: 'link', input: _linkController.text, userId: user.uid);
          break;
        case 'pdf':
          if (_fileBytes == null) throw Exception('No PDF file selected.');
          extractedText = await extractionService.extractContent(
              type: 'pdf', input: _fileBytes!, userId: user.uid);
          break;
        case 'image':
          if (_fileBytes == null) throw Exception('No image file selected.');
          extractedText = await extractionService.extractContent(
              type: 'image', input: _fileBytes!, userId: user.uid);
          break;
        default:
          throw Exception('Please provide some content first.');
      }

      if (extractedText.trim().isEmpty) {
        throw Exception('Could not extract any content from the source.');
      }

      await usageService.recordDeckGeneration(user.uid);
      if (mounted) context.go('/create/extraction-view', extra: extractedText);
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create Study Materials',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: WebColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 16),
                Text(
                  'Transform any content into exam-ready summaries, quizzes, and flashcards',
                  style: TextStyle(
                    fontSize: 18,
                    color: WebColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 60),
                _buildInputCard(),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                _isLoading
                    ? _buildLoadingIndicator()
                    : ElevatedButton.icon(
                        onPressed: _processAndNavigate,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Extract Content'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 24,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
        boxShadow: WebColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildTab(0, Icons.edit_note, 'Text'),
                const SizedBox(width: 8),
                _buildTab(1, Icons.link, 'Link'),
                const SizedBox(width: 8),
                _buildTab(2, Icons.picture_as_pdf, 'PDF'),
                const SizedBox(width: 8),
                _buildTab(3, Icons.image, 'Image'),
              ],
            ),
          ),
          Divider(height: 1, color: WebColors.border),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextInput(),
                _buildLinkInput(),
                _buildFileUpload('pdf'),
                _buildFileUpload('image'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          _resetInputs();
          setState(() {
            _selectedInputType = ['text', 'link', 'pdf', 'image'][index];
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? WebColors.primaryLight : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? WebColors.primary : WebColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? WebColors.primary : WebColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        style: TextStyle(
          color: WebColors.textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText: 'Paste or type your content here...',
          hintStyle: TextStyle(
            color: WebColors.textTertiary,
            fontSize: 16,
          ),
          border: InputBorder.none,
        ),
        onChanged: (_) {
          setState(() => _selectedInputType = 'text');
        },
      ),
    );
  }

  Widget _buildLinkInput() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter URL',
            style: TextStyle(
              color: WebColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            style: TextStyle(
              color: WebColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'https://example.com/article',
              hintStyle: TextStyle(
                color: WebColors.textTertiary,
              ),
              prefixIcon: Icon(Icons.link, color: WebColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: WebColors.border),
              ),
            ),
            onChanged: (_) {
              setState(() => _selectedInputType = 'link');
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.check_circle, color: WebColors.secondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Supports YouTube, articles, and web pages',
                style: TextStyle(
                  color: WebColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileUpload(String type) {
    final hasFile = _fileName != null && _selectedInputType == type;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: hasFile ? _buildFilePreview() : _buildUploadZone(type),
    );
  }

  Widget _buildUploadZone(String type) {
    return GestureDetector(
      onTap: () => _pickFile(type),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: WebColors.border,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: WebColors.backgroundAlt,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: WebColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                type == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                color: WebColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Click to upload ${type.toUpperCase()}',
              style: TextStyle(
                color: WebColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'pdf' ? 'Max size: 15MB' : 'Max size: 10MB',
              style: TextStyle(
                color: WebColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebColors.secondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.secondary),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WebColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.check_circle, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            _fileName!,
            style: TextStyle(
              color: WebColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _fileName = null;
                _fileBytes = null;
              });
            },
            icon: Icon(Icons.close, color: WebColors.textSecondary),
            label: Text(
              'Remove',
              style: TextStyle(color: WebColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: WebColors.primary),
          const SizedBox(height: 24),
          Text(
            'Extracting content...',
            style: TextStyle(
              color: WebColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(
              color: WebColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
