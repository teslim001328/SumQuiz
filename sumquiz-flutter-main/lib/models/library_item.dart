import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/summary_model.dart';
import 'package:myapp/models/quiz_model.dart';
import 'package:myapp/models/flashcard_set.dart';

enum LibraryItemType { summary, quiz, flashcards }

class LibraryItem {
  final String id;
  final String title;
  final LibraryItemType type;
  final Timestamp timestamp;
  final List<String> folderIds; // IDs of folders this item belongs to

  LibraryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    this.folderIds = const [],
  });

  factory LibraryItem.fromSummary(Summary summary) {
    return LibraryItem(
      id: summary.id,
      title: summary.content,
      type: LibraryItemType.summary,
      timestamp: summary.timestamp,
    );
  }

  factory LibraryItem.fromQuiz(Quiz quiz) {
    return LibraryItem(
      id: quiz.id,
      title: quiz.title,
      type: LibraryItemType.quiz,
      timestamp: quiz.timestamp,
    );
  }

  factory LibraryItem.fromFlashcardSet(FlashcardSet flashcardSet) {
    return LibraryItem(
      id: flashcardSet.id,
      title: flashcardSet.title,
      type: LibraryItemType.flashcards,
      timestamp: flashcardSet.timestamp,
    );
  }
}
