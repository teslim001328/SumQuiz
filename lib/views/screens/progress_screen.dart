import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/services/spaced_repetition_service.dart';
import 'package:sumquiz/services/firestore_service.dart';
import 'package:sumquiz/services/progress_service.dart';
import 'package:sumquiz/widgets/activity_chart.dart';
import 'package:sumquiz/widgets/daily_goal_tracker.dart';
import 'package:sumquiz/widgets/goal_setting_dialog.dart';
import 'package:sumquiz/services/user_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Future<Map<String, dynamic>>? _statsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserModel?>(context);
    if (user != null) {
      _statsFuture = _loadStats(user.uid);
    }
  }

  Future<Map<String, dynamic>> _loadStats(String userId) async {
    try {
      final dbService = LocalDatabaseService();
      await dbService.init();
      final srsService =
          SpacedRepetitionService(dbService.getSpacedRepetitionBox());
      final firestoreService = FirestoreService();
      final progressService = ProgressService();

      final srsStatsFuture = srsService.getStatistics(userId);
      final firestoreStatsFuture =
          firestoreService.streamAllItems(userId).first;
      final accuracyFuture = progressService.getAverageAccuracy(userId);
      final timeSpentFuture = progressService.getTotalTimeSpent(userId);

      final results = await Future.wait([
        srsStatsFuture,
        firestoreStatsFuture,
        accuracyFuture,
        timeSpentFuture
      ]);
      final srsStats = results[0] as Map<String, dynamic>;
      final firestoreStats = results[1] as Map<String, List<dynamic>>;
      final averageAccuracy = results[2] as double;
      final totalTimeSpent = results[3] as int;

      final result = {
        ...srsStats,
        'summariesCount': firestoreStats['summaries']?.length ?? 0,
        'quizzesCount': firestoreStats['quizzes']?.length ?? 0,
        'flashcardsCount': firestoreStats['flashcards']?.length ?? 0,
        'averageAccuracy': averageAccuracy,
        'totalTimeSpent': totalTimeSpent,
      };
      developer.log('Stats loaded successfully: $result',
          name: 'ProgressScreen');
      return result;
    } catch (e, s) {
      developer.log('Error loading stats',
          name: 'ProgressScreen', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
            child: Text('Please log in to view your progress.',
                style: GoogleFonts.inter(fontSize: 16))),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Your Progress',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: const Color(0xFF1A237E))),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated Background
          Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              CustomEffect(
                duration: 6.seconds,
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFF3F4F6),
                          Color.lerp(const Color(0xFFE8EAF6),
                              const Color(0xFFC5CAE9), value)!,
                        ],
                      ),
                    ),
                    child: child,
                  );
                },
              )
            ],
            child: Container(),
          ),

          SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildErrorState(user.uid, snapshot.error!);
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(user.uid);
                }

                final stats = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _statsFuture = _loadStats(user.uid);
                    });
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMomentumAndStreak(user),
                        const SizedBox(height: 24),
                        _buildGlassContainer(
                          child: DailyGoalTracker(
                            itemsCompleted: user.itemsCompletedToday,
                            dailyGoal: user.dailyGoal,
                            onSetGoal: () => _setDailyGoal(user),
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'Overall Stats',
                            Icons.pie_chart_outline_rounded),
                        const SizedBox(height: 16),
                        _buildOverallStats(stats)
                            .animate()
                            .fadeIn(delay: 200.ms),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'Recent Activity',
                            Icons.trending_up_rounded),
                        const SizedBox(height: 16),
                        _buildGlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                              height: 200,
                              child: ActivityChart(
                                  activityData: stats['upcomingReviews']
                                          as List<MapEntry<DateTime, int>>? ??
                                      [])),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 24),
                        _buildReviewBanner(
                                stats['dueForReviewCount'] as int? ?? 0)
                            .animate()
                            .fadeIn(delay: 400.ms),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _setDailyGoal(UserModel user) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => GoalSettingDialog(currentGoal: user.dailyGoal),
    );

    if (newGoal != null && newGoal > 0) {
      try {
        await userService.updateDailyGoal(user.uid, newGoal);
        setState(() {
          _statsFuture = _loadStats(user.uid);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update goal: $e')),
        );
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A237E), size: 24),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _buildErrorState(String userId, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text('Something went wrong.',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Could not load your progress. Please try again later.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[700])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  setState(() => _statsFuture = _loadStats(userId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No Progress Data Yet',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700])),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Complete some quizzes or flashcard reviews to see your progress here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _statsFuture = _loadStats(userId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Refresh'),
          )
        ],
      ),
    );
  }

  Widget _buildMomentumAndStreak(UserModel user) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                'Momentum',
                user.currentMomentum.toStringAsFixed(0),
                Icons.local_fire_department_rounded,
                Colors.orangeAccent)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(
                'Streak',
                '${user.missionCompletionStreak} days',
                Icons.whatshot_rounded,
                Colors.redAccent)),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildOverallStats(Map<String, dynamic> stats) {
    final avgAccuracy =
        (stats['averageAccuracy'] as double? ?? 0.0).toStringAsFixed(1);
    final timeSpent = _formatTimeSpent(stats['totalTimeSpent'] as int? ?? 0);
    final summaries = (stats['summariesCount'] as int? ?? 0).toString();
    final quizzes = (stats['quizzesCount'] as int? ?? 0).toString();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Avg. Accuracy', '$avgAccuracy%',
                    Icons.check_circle_outline_rounded, Colors.green)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                    'Time Spent', timeSpent, Icons.timer_rounded, Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Summaries', summaries,
                    Icons.article_rounded, Colors.purple)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                    'Quizzes', quizzes, Icons.quiz_rounded, Colors.teal)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              // Optional trend indicator
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A))),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTimeSpent(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Widget _buildReviewBanner(int dueCount) {
    if (dueCount == 0) return const SizedBox.shrink();
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dueCount items due',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A))),
                Text('Review now to retain better',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }
}
