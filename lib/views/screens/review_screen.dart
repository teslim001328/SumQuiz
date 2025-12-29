import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../models/daily_mission.dart';
import '../../services/mission_service.dart';
import '../../services/user_service.dart';
import 'package:go_router/go_router.dart';

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

    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = "User not found.";
      });
      return;
    }

    try {
      final missionService = Provider.of<MissionService>(context, listen: false);
      final mission = await missionService.generateDailyMission(user.uid);

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

  Future<void> _startMission() async {
    if (_dailyMission == null) return;

    final result = await context.push<double>('/flashcards/mission');

    if (result != null) {
      await _completeMission(result);
    }
  }

  Future<void> _completeMission(double score) async {
    if (_dailyMission == null) return;

    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) return;

    final missionService = Provider.of<MissionService>(context, listen: false);
    await missionService.completeMission(user.uid, _dailyMission!, score);

    final userService = Provider.of<UserService>(context, listen: false);
    await userService.incrementItemsCompleted(user.uid);

    _loadMission(); // Reload to show completed state
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Control'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildMissionDashboard(user),
    );
  }

  Widget _buildMissionDashboard(UserModel? user) {
    if (_dailyMission == null) return const SizedBox.shrink();

    final isCompleted = _dailyMission!.isCompleted;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(theme, user),
          const SizedBox(height: 16),
          _buildDailyGoalProgress(theme, user),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: isCompleted ? 0 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: isCompleted ? BorderSide(color: Colors.green, width: 2) : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isCompleted ? Icons.check_circle : Icons.rocket_launch,
                        size: 80,
                        color: isCompleted ? Colors.green : theme.colorScheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      isCompleted ? 'Mission Complete!' : "Today's Mission",
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (isCompleted)
                      _buildCompletedMissionDetails(theme)
                    else
                      _buildMissionDetails(theme),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isCompleted ? null : _startMission,
                        child: Text(isCompleted ? 'Come back tomorrow' : 'Start Mission'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, UserModel? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Momentum', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  (user?.currentMomentum ?? 0).toStringAsFixed(0),
                  style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalProgress(ThemeData theme, UserModel? user) {
    final dailyGoal = user?.dailyGoal ?? 5;
    final itemsCompleted = user?.itemsCompletedToday ?? 0;
    final double progress = dailyGoal > 0 ? (itemsCompleted / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final bool isGoalAchieved = itemsCompleted >= dailyGoal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Goal', style: theme.textTheme.titleMedium),
                Text('$itemsCompleted/$dailyGoal items', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: isGoalAchieved ? Colors.green : theme.colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              isGoalAchieved ? '🎉 Goal achieved!' : '${(progress * 100).toStringAsFixed(0)}% complete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isGoalAchieved ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionDetails(ThemeData theme) {
    return Column(
      children: [
        _buildMissionDetailRow(theme, Icons.timelapse, "${_dailyMission!.estimatedTimeMinutes} min"),
        const SizedBox(height: 8),
        _buildMissionDetailRow(theme, Icons.filter_none, "${_dailyMission!.flashcardIds.length} cards"),
        const SizedBox(height: 8),
        _buildMissionDetailRow(theme, Icons.speed, "Reward: +${_dailyMission!.momentumReward}"),
      ],
    );
  }

  Widget _buildCompletedMissionDetails(ThemeData theme) {
    return Column(
      children: [
        Text(
          "Great job! You've kept your momentum alive.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          "Score: ${(_dailyMission!.completionScore * 100).toStringAsFixed(0)}%",
          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildMissionDetailRow(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(text, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
