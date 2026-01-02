import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/local_database_service.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../../models/user_model.dart';
import '../../models/daily_mission.dart';
import '../../services/mission_service.dart';
import '../../services/user_service.dart';
import 'flashcards_screen.dart';
import 'summary_screen.dart';
import 'quiz_screen.dart';
import '../../models/local_summary.dart';
import '../../models/local_quiz.dart';
import '../../models/local_flashcard_set.dart';
import 'package:rxdart/rxdart.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  DailyMission? _dailyMission;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMission();
  }

  Future<void> _loadMission() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = "User not found.";
      });
      return;
    }

    try {
      final missionService =
          Provider.of<MissionService>(context, listen: false);
      final mission = await missionService.generateDailyMission(userId);

      setState(() {
        _dailyMission = mission;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Error loading mission: $e";
      });
    }
  }

  Future<List<Flashcard>> _fetchMissionCards(List<String> cardIds) async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (userId == null) return [];

    final localDb = Provider.of<LocalDatabaseService>(context, listen: false);
    final sets = await localDb.getAllFlashcardSets(userId);

    final allCards = sets.expand((s) => s.flashcards).map((localCard) {
      return Flashcard(
        id: localCard.id,
        question: localCard.question,
        answer: localCard.answer,
      );
    }).toList();

    return allCards.where((c) => cardIds.contains(c.id)).toList();
  }

  Future<void> _startMission() async {
    if (_dailyMission == null) return;

    setState(() => _isLoading = true);

    try {
      final cards = await _fetchMissionCards(_dailyMission!.flashcardIds);

      if (cards.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Could not find mission cards. They might be deleted.',
                    style: GoogleFonts.inter())),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      setState(() => _isLoading = false);
      if (!mounted) return;

      final reviewSet = FlashcardSet(
        id: 'mission_session',
        title: 'Daily Mission',
        flashcards: cards,
        timestamp: Timestamp.now(),
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlashcardsScreen(flashcardSet: reviewSet),
        ),
      );

      if (result != null && result is double) {
        await _completeMission(result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to start mission: $e";
      });
    }
  }

  Future<void> _completeMission(double score) async {
    if (_dailyMission == null) return;

    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (userId == null) return;

    final missionService = Provider.of<MissionService>(context, listen: false);
    await missionService.completeMission(userId, _dailyMission!, score);

    final userService = UserService();
    await userService.incrementItemsCompleted(userId);

    _loadMission();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Dashboard',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: const Color(0xFF1A237E))),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF1A237E)),
            onPressed: () => context.push('/settings'),
          ),
        ],
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: GoogleFonts.inter()))
                    : _buildMissionDashboard(user),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionDashboard(UserModel? user) {
    if (_dailyMission == null) return const SizedBox();
    final isCompleted = _dailyMission!.isCompleted;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Header
          Text(
            'Hello, ${user?.displayName ?? 'Student'}',
            style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E)),
          ).animate().fadeIn().slideX(),

          const SizedBox(height: 24),

          // Momentum & Goal Row
          Row(
            children: [
              Expanded(
                  child: _buildGlassStatCard(
                      'Momentum',
                      (user?.currentMomentum ?? 0).toStringAsFixed(0),
                      Icons.local_fire_department_rounded,
                      Colors.orangeAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildDailyGoalCard(user)),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Mission Card
          _buildMissionCard(isCompleted),

          const SizedBox(height: 32),

          // Recent Activity
          Text('Jump Back In',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800])),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _buildRecentActivity(user),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGlassCard(
      {required Widget child, EdgeInsets? padding, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.6),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(
      String label, String value, IconData icon, Color iconColor) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              // Small sparkline or visual placeholder could go here
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A))),
          Text(label,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(UserModel? user) {
    final current = user?.itemsCompletedToday ?? 0;
    final target = user?.dailyGoal ?? 5;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isDone = current >= target;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: isDone ? Colors.green : const Color(0xFF1A237E),
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDone ? Colors.green : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('$current/$target items',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A))),
          Text('Daily Goal',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMissionCard(bool isCompleted) {
    return _buildGlassCard(
        borderColor: isCompleted
            ? Colors.green.withValues(alpha: 0.5)
            : const Color(0xFF1A237E).withValues(alpha: 0.3),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : const Color(0xFF1A237E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.rocket_launch_rounded,
                    color: isCompleted ? Colors.green : const Color(0xFF1A237E),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isCompleted
                              ? 'Mission Accomplished!'
                              : "Today's Mission",
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (!isCompleted)
                        Text('Boost your momentum now',
                            style: GoogleFonts.inter(
                                color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!isCompleted) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMissionMetric(Icons.timelapse,
                      "${_dailyMission!.estimatedTimeMinutes}m"),
                  _buildMissionMetric(Icons.style,
                      "${_dailyMission!.flashcardIds.length} cards"),
                  _buildMissionMetric(
                      Icons.speed, "+${_dailyMission!.momentumReward} pts"),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startMission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    shadowColor: const Color(0xFF1A237E).withValues(alpha: 0.4),
                  ),
                  child: Text('Start Mission',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
              Text(
                "You've earned +${_dailyMission!.momentumReward} momentum score today!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text('Come back tomorrow',
                        style: GoogleFonts.poppins(
                            color: Colors.green[800],
                            fontWeight: FontWeight.w600))),
              ),
            ],
          ],
        ));
  }

  Widget _buildMissionMetric(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5C6BC0)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildRecentActivity(UserModel? user) {
    if (user == null) return const SizedBox();
    final localDb = Provider.of<LocalDatabaseService>(context, listen: false);

    return StreamBuilder(
      stream: Rx.combineLatest3(
        localDb.watchAllFlashcardSets(user.uid),
        localDb.watchAllQuizzes(user.uid),
        localDb.watchAllSummaries(user.uid),
        (sets, quizzes, summaries) {
          final all = <dynamic>[...sets, ...quizzes, ...summaries];
          all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return all.take(5).toList();
        },
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data as List<dynamic>;

        if (items.isEmpty) {
          return Center(
              child: Text('No recent activity',
                  style: GoogleFonts.inter(color: Colors.grey)));
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            String title = item.title;
            IconData icon = Icons.article_rounded;
            Color color = Colors.blue;
            String type = 'Summary';

            if (item is LocalFlashcardSet) {
              icon = Icons.style_rounded;
              color = Colors.orange;
              type = 'Flashcards';
            } else if (item is LocalQuiz) {
              icon = Icons.quiz_rounded;
              color = Colors.teal;
              type = 'Quiz';
            }

            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (item is LocalFlashcardSet) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FlashcardsScreen(
                                      flashcardSet: FlashcardSet(
                                          id: item.id,
                                          title: item.title,
                                          flashcards: item.flashcards
                                              .map((f) => Flashcard(
                                                  id: f.id,
                                                  question: f.question,
                                                  answer: f.answer))
                                              .toList(),
                                          timestamp: Timestamp.fromDate(
                                              item.timestamp)))));
                        } else if (item is LocalQuiz) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => QuizScreen(quiz: item)));
                        } else if (item is LocalSummary) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SummaryScreen(summary: item)));
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const Spacer(),
                          Text(title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(type,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
