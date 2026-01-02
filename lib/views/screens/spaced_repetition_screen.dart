import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:confetti/confetti.dart';
import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../models/local_flashcard.dart';
import '../../models/spaced_repetition.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> {
  late SpacedRepetitionService _spacedRepetitionService;
  late LocalDatabaseService _dbService;
  late ConfettiController _confettiController;
  List<LocalFlashcard> _dueFlashcards = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isFlipping = false;
  String _message = '';

  final GlobalKey<FlipCardState> _flipCardKey = GlobalKey<FlipCardState>();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _initializeAndLoad();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    final box = Hive.box<SpacedRepetitionItem>('spaced_repetition');
    _spacedRepetitionService = SpacedRepetitionService(box);
    _dbService = LocalDatabaseService();
    await _dbService.init();
    await _loadDueFlashcards();
  }

  Future<void> _loadDueFlashcards() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user != null) {
        final allFlashcardSets = await _dbService.getAllFlashcardSets(user.uid);
        final allLocalFlashcards =
            allFlashcardSets.expand((set) => set.flashcards).toList();
        final flashcards = await _spacedRepetitionService.getDueFlashcards(
            user.uid, allLocalFlashcards);
        if (!mounted) return;

        setState(() {
          _dueFlashcards = flashcards;
          _isLoading = false;
          _currentIndex = 0;
          if (flashcards.isEmpty) {
            _message = 'No items are due for review right now. Great job!';
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _message = 'Please log in to review your flashcards.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'An error occurred: $e';
      });
    }
  }

  void _flipCard() {
    if (!_isFlipping) {
      _flipCardKey.currentState?.toggleCard();
      setState(() {
        _isFlipping = true;
      });
    }
  }

  Future<void> _processReview(bool answeredCorrectly) async {
    if (_currentIndex >= _dueFlashcards.length) return;

    final flashcard = _dueFlashcards[_currentIndex];
    try {
      await _spacedRepetitionService.updateReview(
          flashcard.id, answeredCorrectly);

      if (_currentIndex < _dueFlashcards.length - 1) {
        setState(() {
          _currentIndex++;
          _isFlipping = false;
        });
        _flipCardKey.currentState?.toggleCard(); // Flip back to question
      } else {
        setState(() {
          _message = 'You\'ve completed all due flashcards for now!';
          _dueFlashcards.clear();
          _confettiController.play(); // Celebrate!
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Daily Review',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Animated Background
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
                          const Color(0xFF0F2027), // Dark slate
                          Color.lerp(const Color(0xFF203A43),
                              const Color(0xFF2C5364), value)!, // Tealish dark
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _dueFlashcards.isEmpty
                    ? _buildCompletionOrMessageView()
                    : _buildFlashcardReview(),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCompletionOrMessageView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 100, color: Color(0xFF2ECC71))
                .animate()
                .scale()
                .fadeIn(),
            const SizedBox(height: 24),
            Text(_message,
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.1),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Library'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E44AD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardReview() {
    if (_currentIndex >= _dueFlashcards.length) {
      return _buildCompletionOrMessageView();
    }

    final flashcard = _dueFlashcards[_currentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 48), // Spacer to balance
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _dueFlashcards.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.lightGreenAccent),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text('${_currentIndex + 1}/${_dueFlashcards.length}',
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: FlipCard(
              key: _flipCardKey,
              flipOnTouch: false, // We control flips manually
              front: _buildCardSide('Question', flashcard.question, true),
              back: _buildCardSide('Answer', flashcard.answer, false),
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons based on flip state
          SizedBox(
            height: 80,
            child: _isFlipping
                ? _buildAnswerButtons()
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.2)
                : _buildShowAnswerButton()
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.2),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCardSide(String title, String content, bool isQuestion) {
    return GestureDetector(
      onTap: isQuestion ? _flipCard : null,
      child: _buildGlassCard(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(),
                  style: GoogleFonts.inter(
                      color: isQuestion
                          ? Colors.amberAccent
                          : Colors.lightBlueAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(content,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.5,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              if (isQuestion)
                Center(
                    child: Text('Tap to reveal answer',
                        style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic)))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowAnswerButton() {
    return ElevatedButton(
      onPressed: _flipCard,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 56),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: Text('Show Answer',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAnswerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeedbackButton(
            'Hard', Icons.close, Colors.redAccent, () => _processReview(false)),
        _buildFeedbackButton('Easy', Icons.check, Colors.greenAccent.shade700,
            () => _processReview(true)),
      ],
    );
  }

  Widget _buildFeedbackButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(140, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
    );
  }
}
