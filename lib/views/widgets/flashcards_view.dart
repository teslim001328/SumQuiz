import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/flashcard.dart';

class FlashcardsView extends StatefulWidget {
  final String title;
  final List<Flashcard> flashcards;
  final Function(int index, bool knewIt) onReview;
  final VoidCallback onFinish;

  const FlashcardsView({
    super.key,
    required this.title,
    required this.flashcards,
    required this.onReview,
    required this.onFinish,
  });

  @override
  State<FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends State<FlashcardsView> {
  final CardSwiperController _swiperController = CardSwiperController();
  int _currentIndex = 0;

  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (currentIndex == null) {
      widget.onFinish();
    } else {
      setState(() {
        _currentIndex = currentIndex;
      });
    }
    return true;
  }

  void _handleReview(int index, bool knewIt) {
    widget.onReview(index, knewIt);
    _swiperController.swipe(CardSwiperDirection.right);
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('FlashcardsView build: ${widget.flashcards.length} cards',
        name: 'flashcards.view');
    if (widget.flashcards.isEmpty) {
      return Center(
          child: Text("No flashcards available.",
              style: GoogleFonts.poppins(color: Colors.white)));
    }

    // Progress bar value
    double progress = (_currentIndex + 1) / widget.flashcards.length;

    return SafeArea(
      child: Column(
        children: [
          // Header with Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              children: [
                Text(widget.title,
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amberAccent),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_currentIndex + 1}/${widget.flashcards.length}',
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card Swiper
          Expanded(
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: widget.flashcards.length,
              onSwipe: _onSwipe,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) {
                final card = widget.flashcards[index];
                return FlipCard(
                  front: _buildCardSide(card.question, isFront: true),
                  back: _buildCardSide(card.answer,
                      isFront: false, cardIndex: index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSide(String text, {required bool isFront, int? cardIndex}) {
    return _buildGlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header content (e.g., "Question" label)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              isFront ? "QUESTION" : "ANSWER",
              style: GoogleFonts.inter(
                color: isFront
                    ? const Color(0xFF1A237E).withValues(alpha: 0.6)
                    : const Color(0xFFE65100).withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),

          // Footer / Actions
          if (!isFront)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGlassButton(
                    label: "Still Learning",
                    icon: Icons.refresh_rounded,
                    color: Colors.orange,
                    onPressed: () => _handleReview(cardIndex!, false),
                  ),
                  _buildGlassButton(
                    label: "Got It",
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    onPressed: () => _handleReview(cardIndex!, true),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 20, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    "Tap to Flip",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade().scale(),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
