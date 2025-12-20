import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Summary;
import 'package:rxdart/rxdart.dart';
import 'package:sumquiz/models/library_item.dart';
import 'package:sumquiz/models/summary_model.dart';
import 'package:sumquiz/models/quiz_model.dart';
import 'package:sumquiz/models/flashcard_set.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/models/quiz_question.dart';
import 'package:sumquiz/models/flashcard.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_quiz_question.dart';
import 'package:sumquiz/models/local_flashcard.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
import 'package:sumquiz/services/local_database_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  FirebaseFirestore get db => _db;

  Stream<UserModel?> streamUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? UserModel.fromFirestore(snap) : null);
  }

  Future<void> saveUserData(UserModel user) {
    final userData = user.toFirestore();

    // Initialize usage tracking fields if they don't exist
    userData['weeklyUploads'] = FieldValue.increment(0);
    userData['folderCount'] = FieldValue.increment(0);
    userData['srsCardCount'] = FieldValue.increment(0);

    return _db
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
  }

  Future<bool> canGenerate(String uid, String feature) async {
    DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      int dailyCount = doc.data()!['daily_usage'][feature] ?? 0;
      return dailyCount < 1000;
    }
    return false;
  }

  Future<void> incrementUsage(String uid, String feature) {
    return _db.collection('users').doc(uid).set({
      'daily_usage': {feature: FieldValue.increment(1)}
    }, SetOptions(merge: true));
  }

  Stream<List<Summary>> streamSummaries(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('summaries')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((list) =>
            list.docs.map((doc) => Summary.fromFirestore(doc)).toList());
  }

  Stream<List<Quiz>> streamQuizzes(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('quizzes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
            (list) => list.docs.map((doc) => Quiz.fromFirestore(doc)).toList());
  }

  Stream<List<FlashcardSet>> streamFlashcardSets(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('flashcard_sets')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((list) =>
            list.docs.map((doc) => FlashcardSet.fromFirestore(doc)).toList());
  }

  Stream<List<LibraryItem>> streamItems(String userId, String type) {
    switch (type) {
      case 'summaries':
        return streamSummaries(userId)
            .map((items) => items.map(LibraryItem.fromSummary).toList());
      case 'quizzes':
        return streamQuizzes(userId)
            .map((items) => items.map(LibraryItem.fromQuiz).toList());
      case 'flashcards':
        return streamFlashcardSets(userId)
            .map((items) => items.map(LibraryItem.fromFlashcardSet).toList());
      default:
        return Stream.value([]);
    }
  }

  Stream<Map<String, List<LibraryItem>>> streamAllItems(String userId) {
    return CombineLatestStream.combine3(
      streamSummaries(userId)
          .map((list) => list.map(LibraryItem.fromSummary).toList()),
      streamQuizzes(userId)
          .map((list) => list.map(LibraryItem.fromQuiz).toList()),
      streamFlashcardSets(userId)
          .map((list) => list.map(LibraryItem.fromFlashcardSet).toList()),
      (summaries, quizzes, flashcards) => {
        'summaries': summaries,
        'quizzes': quizzes,
        'flashcards': flashcards,
      },
    );
  }

  Future<void> addSummary(String userId, Summary summary) async {
    final newDocRef =
        _db.collection('users').doc(userId).collection('summaries').doc();
    final summaryWithId = summary.copyWith(id: newDocRef.id);

    final localSummary = LocalSummary(
      id: summaryWithId.id,
      title: summaryWithId.title,
      content: summaryWithId.content,
      tags: summaryWithId.tags,
      timestamp: summaryWithId.timestamp.toDate(),
      userId: userId,
      isSynced: false,
    );
    await _localDb.saveSummary(localSummary);

    try {
      await newDocRef.set(summaryWithId.toFirestore());
      await _localDb.updateSummarySyncStatus(summaryWithId.id, true);
    } catch (e) {
      debugPrint('Error saving summary to Firestore: $e');
    }
  }

  Future<void> updateSummary(String userId, String summaryId, String title,
      String content, List<String> tags) async {
    final timestamp = Timestamp.now();
    final localSummary = await _localDb.getSummary(summaryId);
    if (localSummary != null) {
      localSummary.title = title;
      localSummary.content = content;
      localSummary.tags = tags;
      localSummary.timestamp = timestamp.toDate();
      localSummary.isSynced = false;
      await _localDb.saveSummary(localSummary);
    }

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('summaries')
          .doc(summaryId)
          .update({
        'title': title,
        'content': content,
        'tags': tags,
        'timestamp': timestamp,
      });

      await _localDb.updateSummarySyncStatus(summaryId, true);
    } catch (e) {
      debugPrint('Error updating summary in Firestore: $e');
    }
  }

  Future<void> deleteSummary(String userId, String summaryId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('summaries')
        .doc(summaryId)
        .delete();
    await _localDb.deleteSummary(summaryId);
  }

  Future<void> addQuiz(String userId, Quiz quiz) async {
    final newDocRef =
        _db.collection('users').doc(userId).collection('quizzes').doc();
    final quizWithId = quiz.copyWith(id: newDocRef.id);

    final localQuiz = LocalQuiz(
      id: quizWithId.id,
      title: quizWithId.title,
      questions: quizWithId.questions
          .map((q) => LocalQuizQuestion(
                question: q.question,
                options: q.options,
                correctAnswer: q.correctAnswer,
              ))
          .toList(),
      timestamp: quizWithId.timestamp.toDate(),
      userId: userId,
      isSynced: false,
    );
    await _localDb.saveQuiz(localQuiz);

    try {
      await newDocRef.set(quizWithId.toFirestore());
      await _localDb.updateQuizSyncStatus(quizWithId.id, true);
    } catch (e) {
      debugPrint('Error saving quiz to Firestore: $e');
    }
  }

  Future<void> updateQuiz(String userId, String quizId, String title,
      List<QuizQuestion> questions) async {
    final timestamp = Timestamp.now();
    final localQuiz = await _localDb.getQuiz(quizId);
    if (localQuiz != null) {
      localQuiz.title = title;
      localQuiz.questions = questions
          .map((q) => LocalQuizQuestion(
                question: q.question,
                options: q.options,
                correctAnswer: q.correctAnswer,
              ))
          .toList();
      localQuiz.timestamp = timestamp.toDate();
      localQuiz.isSynced = false;
      await _localDb.saveQuiz(localQuiz);
    }

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('quizzes')
          .doc(quizId)
          .update({
        'title': title,
        'questions': questions.map((q) => q.toFirestore()).toList(),
        'timestamp': timestamp,
      });
      await _localDb.updateQuizSyncStatus(quizId, true);
    } catch (e) {
      debugPrint('Error updating quiz in Firestore: $e');
    }
  }

  Future<void> deleteQuiz(String userId, String quizId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .doc(quizId)
        .delete();
    await _localDb.deleteQuiz(quizId);
  }

  Future<void> addFlashcardSet(String userId, FlashcardSet flashcardSet) async {
    final newDocRef =
        _db.collection('users').doc(userId).collection('flashcard_sets').doc();
    final flashcardSetWithId = flashcardSet.copyWith(id: newDocRef.id);

    final localFlashcardSet = LocalFlashcardSet(
      id: flashcardSetWithId.id,
      title: flashcardSetWithId.title,
      flashcards: flashcardSetWithId.flashcards
          .map((f) => LocalFlashcard(
                question: f.question,
                answer: f.answer,
              ))
          .toList(),
      timestamp: flashcardSetWithId.timestamp.toDate(),
      userId: userId,
      isSynced: false,
    );
    await _localDb.saveFlashcardSet(localFlashcardSet);

    try {
      await newDocRef.set(flashcardSetWithId.toFirestore());
      await _localDb.updateFlashcardSetSyncStatus(flashcardSetWithId.id, true);
    } catch (e) {
      debugPrint('Error saving flashcard set to Firestore: $e');
    }
  }

  Future<void> updateFlashcardSet(String userId, String flashcardSetId,
      String title, List<Flashcard> flashcards) async {
    final timestamp = Timestamp.now();
    final localFlashcardSet = await _localDb.getFlashcardSet(flashcardSetId);
    if (localFlashcardSet != null) {
      localFlashcardSet.title = title;
      localFlashcardSet.flashcards = flashcards
          .map((f) => LocalFlashcard(
                question: f.question,
                answer: f.answer,
              ))
          .toList();
      localFlashcardSet.timestamp = timestamp.toDate();
      localFlashcardSet.isSynced = false;
      await _localDb.saveFlashcardSet(localFlashcardSet);
    }

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('flashcard_sets')
          .doc(flashcardSetId)
          .update({
        'title': title,
        'flashcards': flashcards.map((f) => f.toFirestore()).toList(),
        'timestamp': timestamp,
      });
      await _localDb.updateFlashcardSetSyncStatus(flashcardSetId, true);
    } catch (e) {
      debugPrint('Error updating flashcard set in Firestore: $e');
    }
  }

  Future<void> deleteFlashcardSet(String userId, String flashcardSetId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('flashcard_sets')
        .doc(flashcardSetId)
        .delete();
    await _localDb.deleteFlashcardSet(flashcardSetId);
  }

  Future<dynamic> getSpecificItem(String userId, LibraryItem item) async {
    DocumentSnapshot doc;
    switch (item.type) {
      case LibraryItemType.summary:
        doc = await _db
            .collection('users')
            .doc(userId)
            .collection('summaries')
            .doc(item.id)
            .get();
        return Summary.fromFirestore(doc);
      case LibraryItemType.quiz:
        doc = await _db
            .collection('users')
            .doc(userId)
            .collection('quizzes')
            .doc(item.id)
            .get();
        return Quiz.fromFirestore(doc);
      case LibraryItemType.flashcards:
        doc = await _db
            .collection('users')
            .doc(userId)
            .collection('flashcard_sets')
            .doc(item.id)
            .get();
        return FlashcardSet.fromFirestore(doc);
    }
  }

  Future<void> deleteItem(String userId, LibraryItem item) async {
    switch (item.type) {
      case LibraryItemType.summary:
        await deleteSummary(userId, item.id);
        break;
      case LibraryItemType.quiz:
        await deleteQuiz(userId, item.id);
        break;
      case LibraryItemType.flashcards:
        await deleteFlashcardSet(userId, item.id);
        break;
    }
  }
}
