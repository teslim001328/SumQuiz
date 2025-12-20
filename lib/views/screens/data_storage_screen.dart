import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';

/// Modern data storage management screen with improved UI and additional features
/// Allows users to manage offline data, cache, and storage preferences
class DataStorageScreen extends StatelessWidget {
  const DataStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localDB = Provider.of<LocalDatabaseService>(context);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Data & Storage',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStorageInfoCard(context, theme),
                const SizedBox(height: 24),
                _buildDataCard(
                  context,
                  theme: theme,
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear Cache',
                  subtitle: 'Remove temporary files and cached data',
                  onTap: () => _showClearCacheConfirmation(context, localDB),
                ),
                const SizedBox(height: 16),
                _buildDataCard(
                  context,
                  theme: theme,
                  icon: Icons.offline_pin_outlined,
                  title: 'Manage Offline Files',
                  subtitle: 'View and delete downloaded content',
                  onTap: () =>
                      _showOfflineFilesModal(context, theme, localDB, user),
                ),
                const SizedBox(height: 16),
                _buildDataCard(
                  context,
                  theme: theme,
                  icon: Icons.sync_outlined,
                  title: 'Sync Data',
                  subtitle: 'Sync offline data with cloud storage',
                  onTap: () => _syncData(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageInfoCard(BuildContext context, ThemeData theme) {
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.storage_outlined,
                      color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Info',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your app storage and data',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Simulated storage usage
            Text(
              'Current Usage: 42.5 MB',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.42,
              backgroundColor: theme.dividerColor,
              color: theme.colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 MB',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.textTheme.bodySmall?.color)),
                Text('100 MB',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.textTheme.bodySmall?.color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(BuildContext context,
      {required ThemeData theme,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.iconTheme.color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheConfirmation(
      BuildContext context, LocalDatabaseService localDB) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Cache?',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          content: Text(
              'Are you sure you want to clear all cached data? This will free up storage space but may require re-downloading content.',
              style: theme.textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Clear',
                  style: TextStyle(color: theme.colorScheme.error)),
              onPressed: () {
                localDB.clearAllData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showOfflineFilesModal(BuildContext context, ThemeData theme,
      LocalDatabaseService localDB, UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Offline Files',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (user != null)
                FutureBuilder(
                  future: Future.wait([
                    localDB.getAllSummaries(user.uid),
                    localDB.getAllQuizzes(user.uid),
                    localDB.getAllFlashcardSets(user.uid),
                  ]),
                  builder:
                      (context, AsyncSnapshot<List<List<dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData ||
                        snapshot.data!.every((list) => list.isEmpty)) {
                      return Center(
                        child: Column(
                          children: [
                            Icon(Icons.folder_outlined,
                                size: 48, color: theme.iconTheme.color),
                            const SizedBox(height: 16),
                            Text(
                              'No offline files yet.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Download content to view it offline.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      );
                    }

                    final summaries = snapshot.data![0] as List<LocalSummary>;
                    final quizzes = snapshot.data![1] as List<LocalQuiz>;
                    final flashcardSets =
                        snapshot.data![2] as List<LocalFlashcardSet>;

                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ...summaries.map((summary) => _buildOfflineFileTile(
                              context,
                              theme,
                              localDB,
                              'Summary',
                              summary.title,
                              summary.id,
                              () => localDB.deleteSummary(summary.id))),
                          ...quizzes.map((quiz) => _buildOfflineFileTile(
                              context,
                              theme,
                              localDB,
                              'Quiz',
                              quiz.title,
                              quiz.id,
                              () => localDB.deleteQuiz(quiz.id))),
                          ...flashcardSets.map((flashcardSet) =>
                              _buildOfflineFileTile(
                                  context,
                                  theme,
                                  localDB,
                                  'Flashcard Set',
                                  flashcardSet.title,
                                  flashcardSet.id,
                                  () => localDB
                                      .deleteFlashcardSet(flashcardSet.id))),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineFileTile(
      BuildContext context,
      ThemeData theme,
      LocalDatabaseService localDB,
      String type,
      String title,
      String id,
      VoidCallback onDelete) {
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(type, style: theme.textTheme.bodySmall),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            onDelete();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title deleted.'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncData(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Syncing data...',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
        backgroundColor: theme.colorScheme.secondaryContainer,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implement actual sync functionality
  }
}
