import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
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
    if (widget.flashcards.isEmpty) {
      return const Center(child: Text("No flashcards available."));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                        'Card ${_currentIndex + 1}/${widget.flashcards.length}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            Expanded(
              child: CardSwiper(
                controller: _swiperController,
                cardsCount: widget.flashcards.length,
                onSwipe: _onSwipe,
                padding: const EdgeInsets.symmetric(vertical: 30.0),
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
      ),
    );
  }

  Widget _buildCardSide(String text, {required bool isFront, int? cardIndex}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Expanded(
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(text,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge)))),
          if (!isFront)
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeedbackButton("Didn't Know",
                        () => _handleReview(cardIndex!, false), false),
                    _buildFeedbackButton(
                        "Knew It", () => _handleReview(cardIndex!, true), true),
                  ],
                ))
          else
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Tap to Flip",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(
      String text, VoidCallback onPressed, bool knewIt) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: knewIt
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        foregroundColor: knewIt ? Colors.green.shade800 : Colors.red.shade800,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: knewIt ? Colors.green.shade300 : Colors.red.shade300,
                width: 1.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
