import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Update user's daily goal
  Future<void> updateDailyGoal(String userId, int newGoal) async {
    await _db.collection('users').doc(userId).update({
      'dailyGoal': newGoal,
    });
  }

  /// Increment items completed today
  Future<void> incrementItemsCompleted(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final user = UserModel.fromFirestore(userDoc);
    final now = DateTime.now();
    final lastUpdate = user.updatedAt ?? DateTime.now();

    // Check if it's a new day
    final isSameDay = now.year == lastUpdate.year &&
        now.month == lastUpdate.month &&
        now.day == lastUpdate.day;

    int newItemsCompleted = user.itemsCompletedToday;
    if (isSameDay) {
      newItemsCompleted++;
    } else {
      newItemsCompleted = 1; // Reset for new day
    }

    await _db.collection('users').doc(userId).update({
      'itemsCompletedToday': newItemsCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reset daily progress (for testing or manual reset)
  Future<void> resetDailyProgress(String userId) async {
    await _db.collection('users').doc(userId).update({
      'itemsCompletedToday': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reset weekly uploads (should be called periodically)
  Future<void> resetWeeklyUploads(String userId) async {
    await _db.collection('users').doc(userId).update({
      'weeklyUploads': 0,
    });
  }

  /// Check if weekly uploads should be reset and reset if needed
  Future<void> checkAndResetWeeklyUploads(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      if (userData == null) return;

      // Check if we have the lastWeeklyReset field
      if (userData.containsKey('lastWeeklyReset')) {
        final lastReset = (userData['lastWeeklyReset'] as Timestamp).toDate();
        final now = DateTime.now();
        
        // Check if a week has passed since the last reset
        final difference = now.difference(lastReset);
        if (difference.inDays >= 7) {
          // Reset weekly uploads
          await resetWeeklyUploads(userId);
          
          // Update the last reset timestamp
          await _db.collection('users').doc(userId).update({
            'lastWeeklyReset': FieldValue.serverTimestamp(),
          });
          
          developer.log('Weekly uploads reset for user: $userId');
        }
      } else {
        // If there's no lastWeeklyReset field, set it to now
        await _db.collection('users').doc(userId).update({
          'lastWeeklyReset': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      developer.log('Error checking/resetting weekly uploads', error: e);
    }
  }
}
