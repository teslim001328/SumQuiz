import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/services/content_extraction_service.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';

// Enum to represent the single source of content
enum ContentType { text, link, pdf, image }

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  // State variables
  ContentType? _activeContentType;
  final _textController = TextEditingController();
  final _linkController = TextEditingController();
  String? _pdfName;
  Uint8List? _pdfBytes;
  String? _imageName;
  Uint8List? _imageBytes;

  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // Reset all other inputs when one is activated
  void _resetInputs({ContentType? except}) {
    if (except != ContentType.text) _textController.clear();
    if (except != ContentType.link) _linkController.clear();
    if (except != ContentType.pdf) {
      _pdfName = null;
      _pdfBytes = null;
    }
    if (except != ContentType.image) {
      _imageName = null;
      _imageBytes = null;
    }
    _activeContentType = except;
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _resetInputs(except: ContentType.pdf);
        _pdfName = result.files.single.name;
        _pdfBytes = result.files.single.bytes;
        _activeContentType = ContentType.pdf;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _resetInputs(except: ContentType.image);
        _imageName = image.name;
        _imageBytes = bytes;
        _activeContentType = ContentType.image;
      });
    }
  }

  void _processAndNavigate() async {
    if (_activeContentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide some content first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to create content.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final extractionService =
          Provider.of<ContentExtractionService>(context, listen: false);
      String extractedText = '';

      switch (_activeContentType!) {
        case ContentType.text:
          if (_textController.text.trim().isEmpty) {
            throw Exception('The text field is empty.');
          }
          extractedText = await extractionService.extractContent(
              type: 'text', input: _textController.text);
          break;
        case ContentType.link:
          if (_linkController.text.trim().isEmpty) {
            throw Exception('The URL field is empty.');
          }
          extractedText = await extractionService.extractContent(
              type: 'link', input: _linkController.text);
          break;
        case ContentType.pdf:
          if (_pdfBytes == null) {
            throw Exception('No PDF file was selected.');
          }
          extractedText = await extractionService.extractContent(
              type: 'pdf', input: _pdfBytes);
          break;
        case ContentType.image:
          if (_imageBytes == null) {
            throw Exception('No image was selected.');
          }
          extractedText = await extractionService.extractContent(
              type: 'image', input: _imageBytes);
          break;
      }

      if (mounted) {
        context.push('/create/extraction-view', extra: extractedText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process content: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Create Content',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {}, // Profile action placeholder
            icon: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated Gradient Background
          Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              CustomEffect(
                duration: 10.seconds,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2),
                      children: [
                        const TextSpan(text: 'What do you want to \n'),
                        TextSpan(
                            text: 'learn',
                            style:
                                TextStyle(color: Colors.blueAccent.shade100)),
                        const TextSpan(text: ' today?'),
                      ],
                    ),
                  ).animate().fadeIn().slideX(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('PASTE TEXT', Icons.edit)
                      .animate()
                      .fadeIn(delay: 100.ms),
                  _buildPasteTextSection().animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 32),
                  _buildSectionHeader('IMPORT WEBPAGE', Icons.link)
                      .animate()
                      .fadeIn(delay: 200.ms),
                  _buildImportWebpageSection().animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 32),
                  _buildSectionHeader('UPLOAD PDF', Icons.picture_as_pdf)
                      .animate()
                      .fadeIn(delay: 300.ms),
                  _buildUploadPdfSection().animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 32),
                  _buildSectionHeader('SCAN IMAGE', Icons.fullscreen)
                      .animate()
                      .fadeIn(delay: 400.ms),
                  _buildScanImageSection().animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 100), // Extra space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildGenerateButton()
          .animate()
          .fadeIn(delay: 500.ms)
          .slideY(begin: 0.2),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent.shade100, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer(
      {required Widget child, bool isSelected = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: 300.ms,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blueAccent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.blueAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPasteTextSection() {
    return _buildGlassContainer(
      isSelected: _activeContentType == ContentType.text,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        child: TextField(
          onTap: () => setState(() {
            _resetInputs(except: ContentType.text);
            _activeContentType = ContentType.text;
          }),
          controller: _textController,
          maxLines: null,
          expands: true,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Type or paste your notes here for AI summary...',
            hintStyle: GoogleFonts.inter(color: Colors.white38),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildImportWebpageSection() {
    return _buildGlassContainer(
      isSelected: _activeContentType == ContentType.link,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.public, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onTap: () => setState(() {
                  _resetInputs(except: ContentType.link);
                  _activeContentType = ContentType.link;
                }),
                controller: _linkController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://example.com/article',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_activeContentType == ContentType.link)
              Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPdfSection() {
    bool isSelected = _activeContentType == ContentType.pdf && _pdfName != null;
    return GestureDetector(
      onTap: _pickPdf,
      child: _buildGlassContainer(
        isSelected: isSelected,
        child: SizedBox(
          height: 100,
          width: double.infinity,
          child: _pdfName == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, color: Colors.white60, size: 32),
                    const SizedBox(height: 8),
                    Text('Tap to browse PDF',
                        style: GoogleFonts.inter(color: Colors.white70)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.blueAccent, size: 32),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        _pdfName!,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildScanImageSection() {
    return Row(
      children: [
        Expanded(
            child: _buildScanButton('Camera', Icons.camera_alt,
                () => _pickImage(ImageSource.camera))),
        const SizedBox(width: 16),
        Expanded(
            child: _buildScanButton('Gallery', Icons.photo_library,
                () => _pickImage(ImageSource.gallery))),
      ],
    );
  }

  Widget _buildScanButton(String label, IconData icon, VoidCallback onPressed) {
    bool isSelected =
        _activeContentType == ContentType.image && _imageName != null;
    return GestureDetector(
      onTap: onPressed,
      child: _buildGlassContainer(
        isSelected: isSelected,
        child: SizedBox(
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? Icons.check_circle : icon,
                  color: isSelected ? Colors.blueAccent : Colors.white60,
                  size: 32),
              const SizedBox(height: 8),
              Text(
                isSelected ? _imageName! : label,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processAndNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Extract Content',
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.auto_awesome),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
