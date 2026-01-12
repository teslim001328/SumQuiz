import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
import 'package:sumquiz/views/widgets/web/glass_card.dart';
import 'package:sumquiz/views/widgets/web/particle_background.dart';
import 'package:sumquiz/views/widgets/web/exam_stats_card.dart';

class ProgressScreenWeb extends StatefulWidget {
  const ProgressScreenWeb({super.key});

  @override
  State<ProgressScreenWeb> createState() => _ProgressScreenWebState();
}

class _ProgressScreenWebState extends State<ProgressScreenWeb> {
  int _summariesCount = 0;
  int _quizzesCount = 0;
  int _flashcardsCount = 0;
  double _averageAccuracy = 0;
  List<FlSpot> _weeklyActivity = [];
  String _mostActiveDay = 'N/A';
  String _totalTimeDisplay = '0m';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final user = context.read<UserModel?>();
      if (user == null) return;

      final dbService = LocalDatabaseService();
      await dbService.init();

      final summaries = await dbService.getAllSummaries(user.uid);
      final quizzes = await dbService.getAllQuizzes(user.uid);
      final flashcards = await dbService.getAllFlashcardSets(user.uid);

      double totalAccuracy = 0.0;
      int quizCountWithScores = 0;
      int totalSeconds = 0;

      for (var quiz in quizzes) {
        if (quiz.scores.isNotEmpty) {
          final avgQ = quiz.scores.reduce((a, b) => a + b) / quiz.scores.length;
          totalAccuracy += avgQ;
          quizCountWithScores++;
        }
        totalSeconds += quiz.timeSpent;
      }

      final accuracy =
          quizCountWithScores > 0 ? totalAccuracy / quizCountWithScores : 0.0;
      final activity = _calculateWeeklyActivity(summaries, quizzes, flashcards);

      int maxActivityIndex = 0;
      double maxVal = -1;
      for (int i = 0; i < activity.length; i++) {
        if (activity[i].y > maxVal) {
          maxVal = activity[i].y;
          maxActivityIndex = i;
        }
      }

      final activeDate =
          DateTime.now().subtract(Duration(days: maxActivityIndex));
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      String activeDayName = maxVal > 0 ? days[activeDate.weekday - 1] : 'None';

      final minutes = (totalSeconds / 60).floor();
      final hours = (minutes / 60).floor();
      final displayTime =
          hours > 0 ? '${hours}h ${minutes % 60}m' : '${minutes}m';

      if (mounted) {
        setState(() {
          _summariesCount = summaries.length;
          _quizzesCount = quizzes.length;
          _flashcardsCount = flashcards.length;
          _averageAccuracy = accuracy;
          _weeklyActivity = activity;
          _mostActiveDay = activeDayName;
          _totalTimeDisplay = displayTime;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FlSpot> _calculateWeeklyActivity(List<LocalSummary> summaries,
      List<LocalQuiz> quizzes, List<LocalFlashcardSet> flashcards) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final activity = List<double>.filled(7, 0);

    void processItems(List<dynamic> items) {
      for (var item in items) {
        final createdAt = item.timestamp as DateTime;
        final itemDate =
            DateTime(createdAt.year, createdAt.month, createdAt.day);
        final diff = startOfToday.difference(itemDate).inDays;

        if (diff >= 0 && diff < 7) {
          activity[diff]++;
        }
      }
    }

    processItems(summaries);
    processItems(quizzes);
    processItems(flashcards);

    return List.generate(
        7, (index) => FlSpot(index.toDouble(), activity[index]));
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0A0E27);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Particle background
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 30,
              particleColor: Colors.white,
            ),
          ),
          // Gradient orbs
          Positioned(
            top: -100,
            left: 200,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.2),
                      const Color(0xFF10B981).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFB4B4FF)],
                        ).createShader(bounds),
                        child: const Text(
                          "Your Progress",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 8),
                      Text(
                        "Track your learning journey and achievements",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 48),
                      // Stats cards
                      Row(
                        children: [
                          Expanded(
                            child: ExamStatsCard(
                              title: "Summaries",
                              value: _summariesCount.toString(),
                              icon: Icons.article,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              animationDelay: 0,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: ExamStatsCard(
                              title: "Quizzes",
                              value: _quizzesCount.toString(),
                              icon: Icons.quiz,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                              ),
                              animationDelay: 100,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: ExamStatsCard(
                              title: "Flashcards",
                              value: _flashcardsCount.toString(),
                              icon: Icons.style,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                              ),
                              animationDelay: 200,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: ExamStatsCard(
                              title: "Accuracy",
                              value:
                                  "${(_averageAccuracy * 100).toStringAsFixed(0)}%",
                              icon: Icons.trending_up,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              ),
                              animationDelay: 300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Charts row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildActivityChart(),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildInsightsCard(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Activity",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        if (value.toInt() >= 0 && value.toInt() < 7) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyActivity,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: const Color(0xFF6366F1),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.3),
                          const Color(0xFF8B5CF6).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildInsightsCard() {
    final user = Provider.of<UserModel?>(context);
    return GlassCard(
      padding: const EdgeInsets.all(32),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Insights",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          _buildInsightRow("Most Active Day", _mostActiveDay),
          const SizedBox(height: 24),
          _buildInsightRow("Total Study Time", _totalTimeDisplay),
          const SizedBox(height: 24),
          _buildInsightRow(
            "Learning Streak",
            "${user?.missionCompletionStreak ?? 0} Days",
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Keep it up!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "You're doing great",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildInsightRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
