import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/services/content_extraction_service.dart';
import 'dart:typed_data';

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final List<ContentItem> _contentItems = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add an initial text card by default
    _addTextCard();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addTextCard() {
    setState(() {
      _contentItems.add(ContentItem(type: ContentType.text));
    });
  }

  void _addLinkCard() {
    setState(() {
      _contentItems.add(ContentItem(type: ContentType.link));
    });
  }

  void _addPdfCard() {
    setState(() {
      _contentItems.add(ContentItem(type: ContentType.pdf));
    });
  }

  void _addImageCard() {
    setState(() {
      _contentItems.add(ContentItem(type: ContentType.image));
    });
  }

  void _removeCard(int index) {
    setState(() {
      _contentItems.removeAt(index);
    });
  }

  Future<void> _pickPdf(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _contentItems[index].filePath = result.files.single.path;
        _contentItems[index].fileName = result.files.single.name;
        _contentItems[index].fileBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _contentItems[index].filePath = image.path;
        _contentItems[index].fileName = image.name;
        _contentItems[index].fileBytes = bytes;
      });
    }
  }

  Future<void> _captureImage(int index) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _contentItems[index].filePath = image.path;
        _contentItems[index].fileName = image.name;
        _contentItems[index].fileBytes = bytes;
      });
    }
  }

  Future<String> _extractContent() async {
    final StringBuffer combinedContent = StringBuffer();

    for (final item in _contentItems) {
      switch (item.type) {
        case ContentType.text:
          if (item.content != null && item.content!.isNotEmpty) {
            combinedContent.writeln(item.content);
            combinedContent.writeln('\n');
          }
          break;

        case ContentType.link:
          if (item.content != null && item.content!.isNotEmpty) {
            try {
              final extractedText =
                  await ContentExtractionService.extractFromUrl(item.content!);
              combinedContent.writeln(extractedText);
              combinedContent.writeln('\n');
            } catch (e) {
              // Handle error silently or show a warning
              combinedContent.writeln(
                  '[Failed to extract content from URL: ${item.content}]\n');
            }
          }
          break;

        case ContentType.pdf:
          if (item.fileBytes != null) {
            try {
              final extractedText =
                  await ContentExtractionService.extractFromPdfBytes(
                      item.fileBytes!);
              combinedContent.writeln(extractedText);
              combinedContent.writeln('\n');
            } catch (e) {
              combinedContent.writeln(
                  '[Failed to extract content from PDF: ${item.fileName}]\n');
            }
          }
          break;

        case ContentType.image:
          if (item.fileBytes != null) {
            try {
              final extractedText =
                  await ContentExtractionService.extractFromImageBytes(
                      item.fileBytes!);
              combinedContent.writeln(extractedText);
              combinedContent.writeln('\n');
            } catch (e) {
              combinedContent.writeln(
                  '[Failed to extract text from image: ${item.fileName}]\n');
            }
          }
          break;
      }
    }

    return combinedContent.toString().trim();
  }

  Future<void> _navigateToExtraction() async {
    if (_contentItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract all content
      final combinedText = await _extractContent();

      if (combinedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No content to process. Please add some text or files.')),
        );
        return;
      }

      // Navigate to extraction view with the extracted content
      if (mounted) {
        context.push('/extraction-view', extra: combinedText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing content: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Content'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _contentItems.length + 1,
              itemBuilder: (context, index) {
                if (index == _contentItems.length) {
                  return _buildTitleField();
                }
                return _buildContentCard(index, _contentItems[index]);
              },
            ),
          ),
          _buildAddCardButtons(),
          const SizedBox(height: 16),
          _buildNextButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Title (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter a title for your content...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(int index, ContentItem item) {
    switch (item.type) {
      case ContentType.text:
        return _buildTextCard(index);
      case ContentType.link:
        return _buildLinkCard(index);
      case ContentType.pdf:
        return _buildPdfCard(index);
      case ContentType.image:
        return _buildImageCard(index);
    }
  }

  Widget _buildTextCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Text',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeCard(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter or paste your text here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _contentItems[index].content = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Link',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeCard(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              onChanged: (value) {
                _contentItems[index].content = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upload PDF',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeCard(index),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_contentItems[index].filePath == null)
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickPdf(index),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select PDF'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a PDF file from your device',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _contentItems[index].fileName ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _contentItems[index].filePath = null;
                          _contentItems[index].fileName = null;
                          _contentItems[index].fileBytes = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upload Image',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeCard(index),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_contentItems[index].filePath == null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(index),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _captureImage(index),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select an image from gallery or capture a new one',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _contentItems[index].fileName ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _contentItems[index].filePath = null;
                          _contentItems[index].fileName = null;
                          _contentItems[index].fileBytes = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardButtons() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Card',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTextCard,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('Text'),
                ),
                ElevatedButton.icon(
                  onPressed: _addLinkCard,
                  icon: const Icon(Icons.link),
                  label: const Text('Link'),
                ),
                ElevatedButton.icon(
                  onPressed: _addPdfCard,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: _addImageCard,
                  icon: const Icon(Icons.image),
                  label: const Text('Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _navigateToExtraction,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

enum ContentType {
  text,
  link,
  pdf,
  image,
}

class ContentItem {
  ContentType type;
  String? content;
  String? filePath;
  String? fileName;
  Uint8List? fileBytes;

  ContentItem({
    required this.type,
    this.content,
    this.filePath,
    this.fileName,
    this.fileBytes,
  });
}
