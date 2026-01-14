import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sumquiz/theme/web_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/local_database_service.dart';
import '../../../models/flashcard.dart';
import '../../../models/flashcard_set.dart';
import '../../../models/user_model.dart';
import '../../../models/daily_mission.dart';
import '../../../services/mission_service.dart';
import '../../../services/user_service.dart';
import '../flashcards_screen.dart';

class ReviewScreenWeb extends StatefulWidget {
  const ReviewScreenWeb({super.key});

  @override
  State<ReviewScreenWeb> createState() => _ReviewScreenWebState();
}

class _ReviewScreenWebState extends State<ReviewScreenWeb> {
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
            const SnackBar(
                content: Text(
                    'Could not find mission cards. They might be deleted.')),
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
      backgroundColor: WebColors.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: WebColors.primary),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style:
                        TextStyle(color: WebColors.textPrimary, fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeHeader(user),
                          const SizedBox(height: 48),
                          _buildDailyMissionCard(),
                          const SizedBox(height: 32),
                          _buildStatsOverview(user),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildWelcomeHeader(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${user?.displayName.split(' ').first ?? 'Friend'}! 👋',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: WebColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ready to crush your daily mission?',
          style: TextStyle(
            fontSize: 18,
            color: WebColors.textSecondary,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDailyMissionCard() {
    if (_dailyMission == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
        boxShadow: WebColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: WebColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🎯 DAILY MISSION',
                    style: TextStyle(
                      color: WebColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Review 5 Flashcards',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: WebColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Complete today\'s mission to maintain your streak',
                  style: TextStyle(
                    fontSize: 16,
                    color: WebColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _dailyMission!.isCompleted ? null : _startMission,
                  icon: Icon(_dailyMission!.isCompleted
                      ? Icons.check_circle
                      : Icons.play_arrow),
                  label: Text(_dailyMission!.isCompleted
                      ? 'Mission Completed! 🎉'
                      : 'Start Mission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dailyMission!.isCompleted
                        ? WebColors.secondary
                        : WebColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: WebColors.primaryLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.track_changes,
              color: WebColors.primary,
              size: 120,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildStatsOverview(UserModel? user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            value: '${user?.missionCompletionStreak ?? 0} Days',
            label: 'Current Streak',
            color: WebColors.accentOrange,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            icon: Icons.school,
            value: '${user?.itemsCompletedToday ?? 0} Items',
            label: 'Studied Today',
            color: WebColors.secondary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: WebColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
