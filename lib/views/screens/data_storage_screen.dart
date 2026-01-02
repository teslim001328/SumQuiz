import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class DataStorageScreen extends StatelessWidget {
  const DataStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localDB = Provider.of<LocalDatabaseService>(context);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Data & Storage',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Animated Background
          Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              CustomEffect(
                duration: 10.seconds,
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0F2027), // Dark slate
                          Color.lerp(const Color(0xFF203A43),
                              const Color(0xFF2C5364), value)!, // Tealish dark
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _buildStorageInfoCard(context)
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Manage Data')
                          .animate()
                          .fadeIn(delay: 200.ms),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildActionTile(
                              context,
                              icon: Icons.cleaning_services_outlined,
                              title: 'Clear Cache',
                              subtitle: 'Free up space',
                              onTap: () =>
                                  _showClearCacheConfirmation(context, localDB),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            _buildActionTile(
                              context,
                              icon: Icons.offline_pin_outlined,
                              title: 'Offline Files',
                              subtitle: 'Manage downloads',
                              onTap: () => _showOfflineFilesModal(
                                  context, localDB, user),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            _buildActionTile(
                              context,
                              icon: Icons.sync_outlined,
                              title: 'Sync Data',
                              subtitle: 'Sync with cloud',
                              onTap: () => _syncData(context),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent.shade100,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStorageInfoCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storage_outlined,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Storage Usage',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '42.5 MB Used',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent.shade100,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.42,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blueAccent.shade200),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0 MB',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12)),
                    Text('100 MB Limit',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white70),
      title: Text(title,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14, color: Colors.white.withValues(alpha: 0.3)),
    );
  }

  void _showClearCacheConfirmation(
      BuildContext context, LocalDatabaseService localDB) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Clear Cache?',
              style: GoogleFonts.poppins(color: Colors.white)),
          content: Text(
              'Are you sure you want to clear all cached data? This will free up storage space but may require re-downloading content.',
              style: GoogleFonts.inter(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Clear',
                  style: GoogleFonts.inter(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () {
                localDB.clearAllData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully.'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showOfflineFilesModal(
      BuildContext context, LocalDatabaseService localDB, UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2027).withValues(alpha: 0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Offline Files',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  if (user != null)
                    Expanded(
                      child: FutureBuilder(
                        future: Future.wait([
                          localDB.getAllSummaries(user.uid),
                          localDB.getAllQuizzes(user.uid),
                          localDB.getAllFlashcardSets(user.uid),
                        ]),
                        builder: (context,
                            AsyncSnapshot<List<List<dynamic>>> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.every((list) => list.isEmpty)) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open,
                                      size: 48, color: Colors.white24),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No offline files yet.',
                                    style: GoogleFonts.inter(
                                        color: Colors.white54),
                                  ),
                                ],
                              ),
                            );
                          }

                          final summaries =
                              snapshot.data![0] as List<LocalSummary>;
                          final quizzes = snapshot.data![1] as List<LocalQuiz>;
                          final flashcardSets =
                              snapshot.data![2] as List<LocalFlashcardSet>;

                          return ListView(
                            children: [
                              ...summaries.map((summary) =>
                                  _buildOfflineFileTile(
                                      context,
                                      localDB,
                                      'Summary',
                                      summary.title,
                                      summary.id,
                                      () => localDB.deleteSummary(summary.id))),
                              ...quizzes.map((quiz) => _buildOfflineFileTile(
                                  context,
                                  localDB,
                                  'Quiz',
                                  quiz.title,
                                  quiz.id,
                                  () => localDB.deleteQuiz(quiz.id))),
                              ...flashcardSets.map((flashcardSet) =>
                                  _buildOfflineFileTile(
                                      context,
                                      localDB,
                                      'Flashcard Set',
                                      flashcardSet.title,
                                      flashcardSet.id,
                                      () => localDB.deleteFlashcardSet(
                                          flashcardSet.id))),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfflineFileTile(
      BuildContext context,
      LocalDatabaseService localDB,
      String type,
      String title,
      String id,
      VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        title: Text(title,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(type,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.redAccent, size: 20),
          onPressed: () {
            onDelete();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title deleted.'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing data...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement actual sync functionality
  }
}
