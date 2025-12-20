import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../models/editable_content.dart';

class EditContentScreen extends StatefulWidget {
  final EditableContent content;

  const EditContentScreen({super.key, required this.content});

  @override
  State<EditContentScreen> createState() => _EditContentScreenState();
}

class _EditContentScreenState extends State<EditContentScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late List<String> _tags;

  bool _isSaving = false;
  bool _isAiThinking = false;
  Timer? _typingTimer;
  bool _showAiTooltip = false;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.content.title);
    _tags = List.from(widget.content.tags ?? []);
    
    _quillController = QuillController.basic();
    _quillController.document.insert(0, widget.content.content ?? '');

    _quillController.document.changes.listen((_) => _onTyping());
  }

  void _onTyping() {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    setState(() {
      _showAiTooltip = false;
    });
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _quillController.document.toPlainText().trim().isNotEmpty) {
        setState(() {
          _showAiTooltip = true;
        });
      }
    });
  }

  void _handleSave() {
    setState(() => _isSaving = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSaving = false);
    });
  }

  void _handleAiAssist() {
    setState(() => _isAiThinking = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isAiThinking = false);
    });
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _showAddTagDialog() {
    final TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add a Tag', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: tagController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter tag...',
              hintStyle: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.6)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                _addTag(tagController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Add', style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _typingTimer?.cancel();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D0D),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Edit Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: _isSaving
                ? const Icon(Icons.check, color: Colors.greenAccent, key: ValueKey('saved'))
                : const Icon(Icons.save_outlined, color: Colors.white, key: ValueKey('save')),
          ),
          onPressed: _handleSave,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleField(),
                const SizedBox(height: 12),
                _buildTagsSection(),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),
                _buildSummaryField(),
                if (_showAiTooltip)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 4.0),
                    child: Text(
                      'Need help phrasing this? Tap AI Assist.',
                      style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _buildToolbar(),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'Enter title...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color.fromRGBO(255, 255, 255, 0.6),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._tags.map((tag) => Chip(
          backgroundColor: const Color(0xFF1E1E1E),
          label: Text(tag, style: const TextStyle(color: Colors.white)),
          onDeleted: () => _removeTag(tag),
          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white70),
        )),
        GestureDetector(
          onTap: _showAddTagDialog,
          child: const Chip(
            backgroundColor: Colors.transparent,
            side: BorderSide(color: Colors.white38),
            avatar: Icon(Icons.add, color: Colors.white70, size: 18),
            label: Text('Add Tag', style: TextStyle(color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryField() {
    final editorConfig = QuillEditorConfig(
      customStyles: DefaultStyles(
        paragraph: DefaultTextBlockStyle(
          GoogleFonts.inter(fontSize: 16, color: Colors.white, height: 1.5),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(10, 0),
          const VerticalSpacing(0, 0),
          null,
        ),
        placeHolder: DefaultTextBlockStyle(
           GoogleFonts.inter(fontSize: 16, color: const Color.fromRGBO(255, 255, 255, 0.6), height: 1.5),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(10, 0),
          const VerticalSpacing(0, 0),
          null,
        ),
      ),
      embedBuilders: const [],
    );

    return QuillEditor(
      focusNode: _focusNode,
      scrollController: _scrollController,
      controller: _quillController,
      config: editorConfig,
    );
  }

  Widget _buildToolbar() {
    final toolbarConfig = QuillSimpleToolbarConfig(
      showAlignmentButtons: false,
      showBackgroundColorButton: false,
      showCenterAlignment: false,
      showColorButton: false,
      showCodeBlock: false,
      showDirection: false,
      showFontFamily: false,
      showFontSize: false,
      showHeaderStyle: false,
      showIndent: false,
      showInlineCode: false,
      showJustifyAlignment: false,
      showLeftAlignment: false,
      showLink: true,
      showQuote: false,
      showRightAlignment: false,
      showSearchButton: false,
      showSmallButton: false,
      showStrikeThrough: false,
      showSubscript: false,
      showSuperscript: false,
      showUnderLineButton: false,
      buttonOptions: const QuillSimpleToolbarButtonOptions(
        base: QuillToolbarBaseButtonOptions(
          iconTheme: QuillIconTheme(
            iconButtonSelectedData: IconButtonData(color: Color(0xFF6C63FF)),
            iconButtonUnselectedData: IconButtonData(color: Colors.white70),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      color: const Color(0xFF0D0D0D),
      child: Row(
        children: [
          Expanded(
            child: QuillSimpleToolbar(
              controller: _quillController,
              config: toolbarConfig,
            ),
          ),
          const SizedBox(width: 16),
          _buildAiAssistButton(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAiAssistButton() {
    return Material(
      color: const Color(0xFF6C63FF),
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: _handleAiAssist,
        borderRadius: BorderRadius.circular(16.0),
        child: _isAiThinking
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text('Thinking...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              )
            : Shimmer.fromColors(
                baseColor: Colors.white,
                highlightColor: const Color(0xFF6C63FF).withAlpha(150),
                period: const Duration(seconds: 3),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('AI Assist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}