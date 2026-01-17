import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/theme/web_theme.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/services/content_extraction_service.dart';
import 'package:sumquiz/services/enhanced_ai_service.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/services/usage_service.dart';
import 'package:sumquiz/views/widgets/upgrade_dialog.dart';
import 'dart:math' as dart_math;

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
  String _selectedInputType = 'topic'; // Default to topic now

  // Topic-based learning state
  final _topicController = TextEditingController();
  String _topicDepth = 'intermediate';
  double _topicCardCount = 15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);  // Now 5 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _linkController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _resetInputs() {
    _textController.clear();
    _linkController.clear();
    _topicController.clear();
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
        case 'topic':
          // Handle topic-based generation separately
          await _processTopicGeneration(user);
          return;  // Exit early, topic handling is complete
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
    // Premium Design: Full screen animated background
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WebColors.background,
              WebColors.primaryLight.withOpacity(0.5),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildMainCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
          ).createShader(bounds),
          child: const Text(
            'Create Study Materials',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Transform text, links, PDFs, or images into\ninteractive flashcards and quizzes instantly.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: WebColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildMainCard() {
    return Container(
      width: 1000,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: WebColors.primary.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCustomTabBar(),
          const SizedBox(height: 40),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopicInput(),  // NEW: Topic tab first
                _buildTextInput(),
                _buildLinkInput(),
                _buildFileUpload('pdf'),
                _buildFileUpload('image'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          if (_errorMessage.isNotEmpty) _buildErrorBanner(),
          const SizedBox(height: 24),
          _isLoading ? _buildLoadingState() : _buildGenerateButton(),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCustomTabBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: WebColors.backgroundAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: WebColors.primary,
        unselectedLabelColor: WebColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        dividerColor: Colors.transparent,
        onTap: (index) {
          _resetInputs();
          setState(() {
            _selectedInputType = ['topic', 'text', 'link', 'pdf', 'image'][index];
          });
        },
        tabs: [
          _buildTabItem(Icons.lightbulb, 'Learn Topic'),  // NEW tab first
          _buildTabItem(Icons.edit_note, 'Text'),
          _buildTabItem(Icons.link, 'Web Link'),
          _buildTabItem(Icons.picture_as_pdf, 'Upload PDF'),
          _buildTabItem(Icons.image, 'Scan Image'),
        ],
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String label) {
    return Tab(
      height: 50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  // ===========================================================
  // TOPIC-BASED LEARNING
  // ===========================================================
  
  Widget _buildTopicInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [WebColors.primary, const Color(0xFF9333EA)],
            ).createShader(bounds),
            child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'What do you want to learn?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter any topic and we\'ll create a complete study deck for you.',
            style: TextStyle(
              fontSize: 16,
              color: WebColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Topic Input
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _topicController,
              style: TextStyle(
                color: WebColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(20),
                hintText: 'e.g., "Spanish travel phrases", "Python basics"...',
                hintStyle: TextStyle(color: WebColors.textTertiary),
                prefixIcon: Icon(Icons.search, color: WebColors.primary, size: 24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: WebColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: WebColors.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Options Row
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              children: [
                // Depth Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Difficulty',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: WebColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildWebDepthChip('Beginner', 'beginner'),
                          const SizedBox(width: 8),
                          _buildWebDepthChip('Intermediate', 'intermediate'),
                          const SizedBox(width: 8),
                          _buildWebDepthChip('Advanced', 'advanced'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Card Count
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Flashcards: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: WebColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_topicCardCount.toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: WebColors.primary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: WebColors.primary,
                    inactiveTrackColor: WebColors.primary.withOpacity(0.2),
                    thumbColor: WebColors.primary,
                    overlayColor: WebColors.primary.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: _topicCardCount,
                    min: 5,
                    max: 30,
                    divisions: 5,
                    onChanged: (value) => setState(() => _topicCardCount = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // AI Disclaimer
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: Colors.amber[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI-generated content. Verify important facts with trusted sources.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWebDepthChip(String label, String value) {
    final isSelected = _topicDepth == value;
    return GestureDetector(
      onTap: () => setState(() => _topicDepth = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? WebColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? WebColors.primary : WebColors.border,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: WebColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : WebColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Future<void> _processTopicGeneration(UserModel user) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() => _errorMessage = 'Please enter a topic to learn about.');
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final aiService = Provider.of<EnhancedAIService>(context, listen: false);
      final localDb = Provider.of<LocalDatabaseService>(context, listen: false);
      
      final folderId = await aiService.generateFromTopic(
        topic: topic,
        userId: user.uid,
        localDb: localDb,
        depth: _topicDepth,
        cardCount: _topicCardCount.toInt(),
      );
      
      if (mounted) {
        _resetInputs();
        context.push('/library/results-view/$folderId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: WebColors.backgroundAlt.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebColors.border),
      ),
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
          contentPadding: const EdgeInsets.all(24),
          hintText:
              'Paste your lecture notes, article text, or any content here...',
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Paste a URL to Generate Content',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: WebColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _linkController,
            style: TextStyle(
              color: WebColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'https://youtube.com/watch?v=...',
              filled: true,
              fillColor: WebColors.backgroundAlt,
              prefixIcon: Icon(Icons.link, color: WebColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
            ),
            onChanged: (_) {
              setState(() => _selectedInputType = 'link');
            },
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          children: [
            _buildSupportedChip(Icons.play_circle, 'YouTube Videos'),
            _buildSupportedChip(Icons.article, 'Blog Articles'),
            _buildSupportedChip(Icons.web, 'Web Pages'),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportedChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: WebColors.backgroundAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: WebColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: WebColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUpload(String type) {
    final hasFile = _fileName != null && _selectedInputType == type;
    if (hasFile) return _buildFilePreview();

    return GestureDetector(
      onTap: () => _pickFile(type),
      child: Container(
        decoration: BoxDecoration(
          color: WebColors.backgroundAlt.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: WebColors.primary.withOpacity(0.3),
            width: 2,
            style: BorderStyle
                .none, // Can't do dashed easily without package, using dotted image instead
          ),
        ),
        child: CustomPaint(
          painter: DashedRectPainter(
            color: WebColors.primary.withOpacity(0.4),
            strokeWidth: 2,
            gap: 8,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: WebColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/web/upload_illustration.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  'Click to upload ${type.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: WebColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  type == 'pdf'
                      ? 'Supports standard PDF files up to 15MB'
                      : 'Supports JPG, PNG up to 10MB',
                  style: TextStyle(
                    fontSize: 15,
                    color: WebColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: WebColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Browse Files',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildFilePreview() {
    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WebColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 40,
              ),
            ).animate().scale(),
            const SizedBox(height: 20),
            Text(
              'File Selected Ready',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: WebColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _fileName!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: WebColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _fileName = null;
                  _fileBytes = null;
                });
              },
              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              label: Text(
                'Remove File',
                style: TextStyle(color: Colors.red[400]),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade100),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: const Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Text(
            _errorMessage,
            style: TextStyle(
              color: const Color(0xFFDC2626),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [WebColors.primary, const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: WebColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _processAndNavigate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Generate Study Material',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2)),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(WebColors.primary),
            strokeWidth: 4,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Analyzing content with AI...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: WebColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This usually takes 5-10 seconds',
          style: TextStyle(
            color: WebColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Simple dashed border painter
class DashedRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;

  DashedRectPainter(
      {this.strokeWidth = 2.0, this.color = Colors.grey, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = size.width;
    double y = size.height;

    Path _topPath = getDashedPath(
      a: const Point(0, 0),
      b: Point(x, 0),
      gap: gap,
    );

    Path _rightPath = getDashedPath(
      a: Point(x, 0),
      b: Point(x, y),
      gap: gap,
    );

    Path _bottomPath = getDashedPath(
      a: Point(0, y),
      b: Point(x, y),
      gap: gap,
    );

    Path _leftPath = getDashedPath(
      a: const Point(0, 0),
      b: Point(0, y),
      gap: gap,
    );

    canvas.drawPath(_topPath, dashedPaint);
    canvas.drawPath(_rightPath, dashedPaint);
    canvas.drawPath(_bottomPath, dashedPaint);
    canvas.drawPath(_leftPath, dashedPaint);
  }

  Path getDashedPath({
    required Point a,
    required Point b,
    required double gap,
  }) {
    Size size = Size(b.x - a.x, b.y - a.y);
    Path path = Path();
    path.moveTo(a.x, a.y);
    bool shouldDraw = true;
    Point currentPoint = Point(a.x, a.y);

    num radians = dart_math.atan(size.height / size.width);

    num dx = gap * dart_math.cos(radians);
    num dy = gap * dart_math.sin(radians);

    while (shouldDraw) {
      currentPoint = Point(
        currentPoint.x + dx,
        currentPoint.y + dy,
      );
      if (shouldDraw) {
        path.lineTo(currentPoint.x, currentPoint.y);
      } else {
        path.moveTo(currentPoint.x, currentPoint.y);
      }
      shouldDraw = !shouldDraw;
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class Point {
  final double x;
  final double y;
  const Point(this.x, this.y);
}
