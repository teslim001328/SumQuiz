import 'package:cloud_firestore/cloud_firestore.dart';

class UsageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  UsageService(this.uid);

  Future<bool> canPerformAction(String action) async {
    final doc = await _firestore.collection('users').doc(uid).collection('usage').doc(_today()).get();
    if (!doc.exists) {
      return true;
    }
    final usage = doc.data()!;
    final limit = _getLimitForAction(action);
    return (usage[action] ?? 0) < limit;
  }

  Future<void> recordAction(String action) async {
    final docRef = _firestore.collection('users').doc(uid).collection('usage').doc(_today());
    await docRef.set({action: FieldValue.increment(1)}, SetOptions(merge: true));
  }

  int _getLimitForAction(String action) {
    switch (action) {
      case 'summaries':
        return 5;
      case 'quizzes':
        return 3;
      case 'flashcards':
        return 3;
      default:
        return 0;
    }
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
