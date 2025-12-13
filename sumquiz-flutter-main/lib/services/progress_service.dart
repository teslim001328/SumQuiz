import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> getSummariesCount(String userId) async {
    final snapshot =
        await _db.collection('users').doc(userId).collection('summaries').get();
    return snapshot.docs.length;
  }

  Future<int> getQuizzesCount(String userId) async {
    final snapshot =
        await _db.collection('users').doc(userId).collection('quizzes').get();
    return snapshot.docs.length;
  }

  Future<int> getFlashcardsCount(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .get();
    return snapshot.docs.length;
  }

  Future<List<FlSpot>> getWeeklyActivity(String userId) async {
    final today = DateTime.now();
    final last7Days =
        List.generate(7, (index) => today.subtract(Duration(days: index)));
    final activity = <double>[0, 0, 0, 0, 0, 0, 0];

    final summaries = await _db
        .collection('users')
        .doc(userId)
        .collection('summaries')
        .where('created_at', isGreaterThanOrEqualTo: last7Days.last)
        .get();

    final quizzes = await _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .where('created_at', isGreaterThanOrEqualTo: last7Days.last)
        .get();

    final flashcards = await _db
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .where('created_at', isGreaterThanOrEqualTo: last7Days.last)
        .get();

    for (var doc in summaries.docs) {
      final createdAt = (doc.data()['created_at'] as Timestamp).toDate();
      final index = 6 - today.difference(createdAt).inDays;
      if (index >= 0 && index < 7) {
        activity[index]++;
      }
    }

    for (var doc in quizzes.docs) {
      final createdAt = (doc.data()['created_at'] as Timestamp).toDate();
      final index = 6 - today.difference(createdAt).inDays;
      if (index >= 0 && index < 7) {
        activity[index]++;
      }
    }

    for (var doc in flashcards.docs) {
      final createdAt = (doc.data()['created_at'] as Timestamp).toDate();
      final index = 6 - today.difference(createdAt).inDays;
      if (index >= 0 && index < 7) {
        activity[index]++;
      }
    }

    return List.generate(
        7, (index) => FlSpot(index.toDouble(), activity[index]));
  }
}
