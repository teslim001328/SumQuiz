import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../models/spaced_repetition.dart';
import '../models/local_flashcard.dart';

class SpacedRepetitionService {
  final Box<SpacedRepetitionItem> _box;
  final Uuid _uuid = const Uuid();

  SpacedRepetitionService(this._box);

  Future<void> scheduleReview(String flashcardId, String userId) async {
    final now = DateTime.now().toUtc();
    final newItem = SpacedRepetitionItem(
      id: _uuid.v4(),
      userId: userId,
      contentId: flashcardId,
      contentType: 'flashcard',
      nextReviewDate: now,
      lastReviewed: now,
      createdAt: now,
      updatedAt: now,
    );
    await _box.put(newItem.id, newItem);
  }

  Future<void> updateReview(String itemId, bool answeredCorrectly) async {
    final item = _box.get(itemId);
    if (item == null) return;

    final now = DateTime.now().toUtc();
    int repetitionCount;
    double easeFactor;
    int interval;
    int correctStreak;

    if (answeredCorrectly) {
      correctStreak = item.correctStreak + 1;
      repetitionCount = item.repetitionCount + 1;
      easeFactor = item.easeFactor + (0.1 - (5 - 4) * (0.08 + (5 - 4) * 0.02));
      if (easeFactor < 1.3) easeFactor = 1.3;

      if (repetitionCount == 1) {
        interval = 1;
      } else if (repetitionCount == 2) {
        interval = 6;
      } else {
        interval = (item.interval * easeFactor).round();
      }
    } else {
      correctStreak = 0;
      repetitionCount = 0; // Reset repetition count
      interval = 1; // Review again tomorrow
      easeFactor = item.easeFactor; // E-factor does not change on incorrect answer
    }

    final updatedItem = SpacedRepetitionItem(
      id: item.id,
      userId: item.userId,
      contentId: item.contentId,
      contentType: item.contentType,
      nextReviewDate: now.add(Duration(days: interval)),
      lastReviewed: now,
      createdAt: item.createdAt,
      updatedAt: now,
      interval: interval,
      easeFactor: easeFactor,
      repetitionCount: repetitionCount,
      correctStreak: correctStreak,
    );

    await _box.put(item.id, updatedItem);
  }

  Future<List<String>> getDueFlashcardIds(String userId) async {
    final now = DateTime.now().toUtc();
    return _box.values
        .where((item) =>
            item.userId == userId &&
            item.contentType == 'flashcard' &&
            item.nextReviewDate.isBefore(now))
        .map((item) => item.contentId)
        .toList();
  }

  Future<List<LocalFlashcard>> getDueFlashcards(
      String userId, List<LocalFlashcard> allFlashcards) async {
    final dueItemIds = await getDueFlashcardIds(userId);
    final dueItemIdsSet = dueItemIds.toSet();

    return allFlashcards
        .where((flashcard) => dueItemIdsSet.contains(flashcard.id))
        .toList();
  }

  Future<Map<String, dynamic>> getStatistics(String userId) async {
    final now = DateTime.now().toUtc();
    final startOfToday = DateTime.utc(now.year, now.month, now.day);
    final endOfWeek = startOfToday.add(const Duration(days: 7));

    final userItems = _box.values.where((item) => item.userId == userId).toList();

    final dueForReviewCount = userItems
        .where((item) => item.nextReviewDate.isBefore(now))
        .length;

    final upcomingReviews = userItems
        .where((item) =>
            item.nextReviewDate.isAfter(startOfToday) &&
            item.nextReviewDate.isBefore(endOfWeek))
        .groupListsBy((item) => DateTime.utc(
            item.nextReviewDate.year, item.nextReviewDate.month, item.nextReviewDate.day))
        .entries
        .map((entry) => MapEntry(entry.key, entry.value.length))
        .sortedBy<DateTime>((entry) => entry.key)
        .toList();

    return {
      'dueForReviewCount': dueForReviewCount,
      'upcomingReviews': upcomingReviews,
    };
  }
}
