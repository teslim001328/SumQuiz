import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/services/local_database_service.dart';

class QuizViewModel extends ChangeNotifier {
  final LocalDatabaseService _localDbService = LocalDatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  List<LocalQuiz> _quizzes = [];
  List<LocalQuiz> get quizzes => _quizzes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  QuizViewModel() {
    _localDbService.init();
  }

  void setUserId(String? userId) {
    _userId = userId;
    if (_userId != null) {
      _loadQuizzes();
    } else {
      _quizzes = [];
      notifyListeners();
    }
  }

  Future<void> _loadQuizzes() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .where('userId', isEqualTo: _userId)
          .get();
      
      _quizzes = snapshot.docs.map((doc) {
        final data = doc.data();
        return LocalQuiz(
          id: doc.id,
          title: data['title'] ?? '',
          scores: List<double>.from(data['scores'] ?? []),
          questions: const [], // Questions are not stored in Firestore for this view model
          userId: data['userId'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

    } catch (e) {
      debugPrint('Error loading quizzes from Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  double get averageScore {
    if (_quizzes.isEmpty) return 0.0;
    final allScores = _quizzes.expand((quiz) => quiz.scores).toList();
    if (allScores.isEmpty) return 0.0;
    return allScores.reduce((value, element) => value + element) / allScores.length;
  }

  int get totalQuizzesTaken {
    return _quizzes.fold(0, (previousValue, element) => previousValue + element.scores.length);
  }

  int get totalPerfectScores {
    return _quizzes.fold(0, (previousValue, element) {
      return previousValue + element.scores.where((score) => score == element.questions.length).length;
    });
  }
}
