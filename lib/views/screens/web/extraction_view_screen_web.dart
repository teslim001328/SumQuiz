import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/enhanced_ai_service.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/services/usage_service.dart';
import 'package:sumquiz/services/notification_integration.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/views/widgets/upgrade_dialog.dart';
import 'package:sumquiz/services/auth_service.dart';
import 'package:sumquiz/views/widgets/web/glass_card.dart';
import 'package:sumquiz/views/widgets/web/neon_button.dart';
import 'package:sumquiz/views/widgets/web/particle_background.dart';

class ExtractionViewScreenWeb extends StatefulWidget {
  final String? initialText;

  const ExtractionViewScreenWeb({super.key, this.initialText});

  @override
  State<ExtractionViewScreenWeb> createState() =>
      _ExtractionViewScreenWebState();
}

enum OutputType { summary, quiz, flashcards }

class _ExtractionViewScreenWebState extends State<ExtractionViewScreenWeb> {
  late TextEditingController _textController;
  final TextEditingController _titleController =
      TextEditingController(text: 'Untitled Creation');
  final Set<OutputType> _selectedOutputs = {OutputType.summary};
  bool _isLoading = false;
  String _loadingMessage = 'Generating...';

  static const int minTextLength = 10;

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

  void _toggleOutput(OutputType type) {
    if (type == OutputType.flashcards) {
      final user = context.read<UserModel?>();
      if (user != null && !user.isPro) {
        showDialog(
          context: context,
          builder: (_) =>
              const UpgradeDialog(featureName: 'Interactive Flashcards'),
        );
        return;
      }
    }

    setState(() {
      if (_selectedOutputs.contains(type)) {
        _selectedOutputs.remove(type);
      } else {
        _selectedOutputs.add(type);
      }
    });
  }

  Future<void> _handleGenerate() async {
    if (_textController.text.trim().length < minTextLength) {
      _showError(
          'Text is too short. Please provide at least $minTextLength characters.');
      return;
    }

    if (_selectedOutputs.isEmpty) {
      _showError('Please select at least one output type.');
      return;
    }

    final user = context.read<UserModel?>();

    if (user != null) {
      final usageService = UsageService();
      if (!await usageService.canGenerateDeck(user.uid)) {
        if (mounted) {
          showDialog(
              context: context,
              builder: (_) => const UpgradeDialog(featureName: 'Daily Limit'));
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Preparing generation...';
    });

    try {
      final aiService = context.read<EnhancedAIService>();
      final localDb = context.read<LocalDatabaseService>();
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      final userId = currentUser.uid;
      final requestedOutputs = _selectedOutputs.map((e) => e.name).toList();

      final folderId = await aiService.generateAndStoreOutputs(
        text: _textController.text,
        title: _titleController.text.isNotEmpty
            ? _titleController.text
            : 'Untitled Creation',
        requestedOutputs: requestedOutputs,
        userId: userId,
        localDb: localDb,
        onProgress: (message) {
          if (mounted) {
            setState(() => _loadingMessage = message);
          }
        },
      );

      if (user != null) {
        await UsageService().recordDeckGeneration(user.uid);
      }

      // 🔔 Schedule notifications after content generation
      if (mounted) {
        try {
          await NotificationIntegration.onContentGenerated(
            context,
            userId,
            _titleController.text.isNotEmpty
                ? _titleController.text
                : 'Untitled Creation',
          );
        } catch (e) {
          debugPrint('Failed to schedule notifications: $e');
        }
      }

      if (mounted) context.go('/library/results-view/$folderId');
    } catch (e) {
      if (mounted) _showError('Generation failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0A0E27);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Particle background
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 30,
              particleColor: Colors.white,
            ),
          ),
          // Gradient orb
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.25),
                      const Color(0xFF6366F1).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Row(
                  children: [
                    // Left: Editor
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF8B5CF6)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.edit_note,
                                          color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Source Content",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  maxLines: null,
                                  expands: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(24),
                                    border: InputBorder.none,
                                    hintText:
                                        "Review and edit your content here...",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().slideX(begin: -0.05).fadeIn(),
                    // Right: Configuration
                    SizedBox(
                      width: 400,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 24, right: 24, bottom: 24),
                        child: GlassCard(
                          padding: const EdgeInsets.all(32),
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Configuration",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Title
                              Text(
                                "Title",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: TextField(
                                  controller: _titleController,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter title...",
                                    hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.4)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Output types
                              Text(
                                "Generate",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...OutputType.values.map((type) {
                                final isSelected =
                                    _selectedOutputs.contains(type);
                                final gradients = {
                                  OutputType.summary: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6)
                                    ],
                                  ),
                                  OutputType.quiz: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF06B6D4)
                                    ],
                                  ),
                                  OutputType.flashcards: const LinearGradient(
                                    colors: [
                                      Color(0xFFEC4899),
                                      Color(0xFFF97316)
                                    ],
                                  ),
                                };
                                final icons = {
                                  OutputType.summary: Icons.article,
                                  OutputType.quiz: Icons.quiz,
                                  OutputType.flashcards: Icons.style,
                                };

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onTap: () => _toggleOutput(type),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient:
                                            isSelected ? gradients[type] : null,
                                        color: !isSelected
                                            ? Colors.white.withOpacity(0.05)
                                            : null,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: gradients[type]!
                                                      .colors
                                                      .first
                                                      .withOpacity(0.4),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            icons[type],
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            type.name.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const Spacer(),
                              // Generate button
                              if (_isLoading)
                                _buildLoadingIndicator()
                              else
                                NeonButton(
                                  text: 'GENERATE CONTENT',
                                  onPressed: _handleGenerate,
                                  icon: Icons.auto_awesome,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899)
                                    ],
                                  ),
                                  glowColor: const Color(0xFF6366F1),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().slideX(begin: 0.05).fadeIn(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      blur: 20,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
            ).createShader(bounds),
            child: const Text(
              'Review & Generate',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _loadingMessage,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.2));
  }
}
