import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/theme/web_theme.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';

class ProgressScreenWeb extends StatefulWidget {
  const ProgressScreenWeb({super.key});

  @override
  State<ProgressScreenWeb> createState() => _ProgressScreenWebState();
}

class _ProgressScreenWebState extends State<ProgressScreenWeb> {
  int _totalItems = 0;
  int _totalQuizzes = 0;
  int _totalFlashcards = 0;
  List<int> _weeklyActivity = List.filled(7, 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = context.read<UserModel?>();
    if (user == null) return;

    final db = context.read<LocalDatabaseService>();

    try {
      final summaries = await db.getAllSummaries(user.uid);
      final quizzes = await db.getAllQuizzes(user.uid);
      final flashcards = await db.getAllFlashcardSets(user.uid);

      setState(() {
        _totalItems = summaries.length;
        _totalQuizzes = quizzes.length;
        _totalFlashcards = flashcards.length;
        _weeklyActivity =
            _calculateWeeklyActivity(summaries, quizzes, flashcards);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<int> _calculateWeeklyActivity(List<LocalSummary> summaries,
      List<LocalQuiz> quizzes, List<LocalFlashcardSet> flashcards) {
    final activity = List.filled(7, 0);
    final now = DateTime.now();

    void processItems(List<dynamic> items) {
      for (var item in items) {
        final daysDiff = now.difference(item.timestamp).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          activity[6 - daysDiff]++;
        }
      }
    }

    processItems(summaries);
    processItems(quizzes);
    processItems(flashcards);

    return activity;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      backgroundColor: WebColors.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: WebColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: WebColors.textPrimary,
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Study Materials',
                              _totalItems.toString(),
                              Icons.article,
                              WebColors.primary,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildStatCard(
                              'Quizzes',
                              _totalQuizzes.toString(),
                              Icons.quiz,
                              WebColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildStatCard(
                              'Flashcard Sets',
                              _totalFlashcards.toString(),
                              Icons.style,
                              WebColors.accentPink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildActivityChart(),
                      const SizedBox(height: 40),
                      _buildInsightsCard(user),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
        boxShadow: WebColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: WebColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildActivityChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_weeklyActivity.reduce((a, b) => a > b ? a : b) + 2)
                    .toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
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
                        return Text(
                          days[value.toInt()],
                          style: TextStyle(
                            color: WebColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyActivity[index].toDouble(),
                        color: WebColors.primary,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildInsightsCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildInsightRow(
              'Current Streak', '${user?.missionCompletionStreak ?? 0} days'),
          _buildInsightRow(
              'Items Completed Today', '${user?.itemsCompletedToday ?? 0}'),
          _buildInsightRow('Daily Goal', '${user?.dailyGoal ?? 3} items'),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: WebColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: WebColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
