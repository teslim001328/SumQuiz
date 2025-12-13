import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/local_database_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/local_summary.dart';
import 'package:myapp/models/local_quiz.dart';
import 'package:myapp/models/local_flashcard_set.dart';

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
          style: theme.textTheme.headlineSmall,
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
                _buildDataCard(
                  context,
                  theme: theme,
                  title: 'Clear Local Data / Cache',
                  onTap: () => _showClearCacheConfirmation(context, localDB),
                ),
                const SizedBox(height: 16),
                _buildDataCard(
                  context,
                  theme: theme,
                  title: 'Manage Offline Files',
                  onTap: () => _showOfflineFilesModal(context, theme, localDB, user),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, {required ThemeData theme, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.iconTheme.color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheConfirmation(BuildContext context, LocalDatabaseService localDB) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache?'),
          content: const Text('Are you sure you want to clear all local data? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () {
                localDB.clearAllData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local data cleared.'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showOfflineFilesModal(BuildContext context, ThemeData theme, LocalDatabaseService localDB, UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Offline Files',
                style: theme.textTheme.headlineSmall,
              ),
              const Divider(height: 32),
              if (user != null)
                FutureBuilder(
                  future: Future.wait([
                    localDB.getAllSummaries(user.uid),
                    localDB.getAllQuizzes(user.uid),
                    localDB.getAllFlashcardSets(user.uid),
                  ]),
                  builder: (context, AsyncSnapshot<List<List<dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.every((list) => list.isEmpty)) {
                      return Center(
                        child: Text(
                          'No offline files yet.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }

                    final summaries = snapshot.data![0] as List<LocalSummary>;
                    final quizzes = snapshot.data![1] as List<LocalQuiz>;
                    final flashcardSets = snapshot.data![2] as List<LocalFlashcardSet>;

                    return Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ...summaries.map((summary) => _buildOfflineFileTile(context, theme, localDB, 'Summary', summary.title, summary.id, () => localDB.deleteSummary(summary.id))),
                          ...quizzes.map((quiz) => _buildOfflineFileTile(context, theme, localDB, 'Quiz', quiz.title, quiz.id, () => localDB.deleteQuiz(quiz.id))),
                          ...flashcardSets.map((flashcardSet) => _buildOfflineFileTile(context, theme, localDB, 'Flashcard Set', flashcardSet.title, flashcardSet.id, () => localDB.deleteFlashcardSet(flashcardSet.id))),
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

  Widget _buildOfflineFileTile(BuildContext context, ThemeData theme, LocalDatabaseService localDB, String type, String title, String id, VoidCallback onDelete) {
    return ListTile(
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(type, style: theme.textTheme.bodySmall),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          onDelete();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title deleted.'),
            ),
          );
        },
      ),
    );
  }
}
