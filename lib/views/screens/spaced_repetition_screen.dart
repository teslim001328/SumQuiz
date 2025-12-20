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
  Color _backgroundColor = const Color(0xFF1A237E); // Initial Blue

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
          _backgroundColor = const Color(0xFF1A237E); // Reset to blue
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
        _backgroundColor = const Color(0xFF1B5E20); // Animate to Green
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
          _backgroundColor = const Color(0xFF1A237E); // Animate back to Blue
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
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            color: _backgroundColor,
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)))
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

  Widget _buildCompletionOrMessageView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 100, color: Color(0xFF2ECC71)),
            const SizedBox(height: 24),
            Text(_message,
                style: GoogleFonts.oswald(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
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
            ),
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
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop()),
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _dueFlashcards.length,
                  backgroundColor: Colors.white.withAlpha(77),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.lightGreenAccent),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 50), // Balance the close button
            ],
          ),
          const SizedBox(height: 8),
          Text('Card ${_currentIndex + 1}/${_dueFlashcards.length}',
              style: GoogleFonts.roboto(color: Colors.white70)),
          const SizedBox(height: 16),

          Expanded(
            child: FlipCard(
              key: _flipCardKey,
              flipOnTouch: false, // We control flips manually
              front: _buildCardSide('Question', flashcard.question, true),
              back: _buildCardSide('Answer', flashcard.answer, false),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons based on flip state
          _isFlipping ? _buildAnswerButtons() : _buildShowAnswerButton(),
        ],
      ),
    );
  }

  Widget _buildCardSide(String title, String content, bool isQuestion) {
    return GestureDetector(
      onTap: isQuestion ? _flipCard : null,
      child: Card(
        color: Colors.black.withAlpha(102),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 10,
        shadowColor: Colors.black.withAlpha(128),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.oswald(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white54, thickness: 1, height: 24),
              Expanded(
                child: Center(
                  child: Text(content,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.5,
                          fontWeight: FontWeight.w500)),
                ),
              ),
              if (isQuestion)
                const Center(
                    child: Text('Tap to reveal answer',
                        style: TextStyle(
                            color: Colors.white70,
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
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: Colors.white.withAlpha(230),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text('Show Answer',
          style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAnswerButtons() {
    return Column(
      children: [
        Text('Did you remember the answer?',
            style: GoogleFonts.roboto(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildFeedbackButton('No', Icons.close,
                    Colors.red.shade400, () => _processReview(false))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildFeedbackButton('Yes', Icons.check,
                    Colors.green.shade400, () => _processReview(true))),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(140, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: color.withAlpha(128),
      ),
    );
  }
}
