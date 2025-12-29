import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/models/folder.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/view_models/quiz_view_model.dart';
import 'package:sumquiz/views/widgets/folder_card.dart';
import 'package:sumquiz/views/widgets/item_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserModel?>(context);
    if (user != null) {
      Provider.of<QuizViewModel>(context, listen: false).initializeForUser(user.uid);
    }
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _showCreationMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: const Text('Create Quiz'),
            onTap: () {
              Navigator.of(ctx).pop();
              context.go('/create', extra: 'quiz');
            },
          ),
          ListTile(
            leading: const Icon(Icons.style_outlined),
            title: const Text('Create Flashcards'),
            onTap: () {
              Navigator.of(ctx).pop();
              context.go('/create', extra: 'flashcards');
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Create Summary'),
            onTap: () {
              Navigator.of(ctx).pop();
              context.go('/create', extra: 'summary');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Library', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: user == null
          ? _buildLoggedOutView(theme)
          : _buildLibraryContent(user.uid, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreationMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLibraryContent(String userId, ThemeData theme) {
    return Column(
      children: [
        _buildSearchBar(theme),
        _buildTabBar(theme),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFolderList(userId, theme),
              _buildSummaryList(userId, theme),
              _buildQuizList(theme),
              _buildFlashcardList(userId, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search library...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          filled: true,
          fillColor: theme.cardColor,
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: theme.colorScheme.primary,
      unselectedLabelColor: theme.textTheme.bodySmall?.color,
      indicatorColor: theme.colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(text: 'Folders'),
        Tab(text: 'Summaries'),
        Tab(text: 'Quizzes'),
        Tab(text: 'Flashcards'),
      ],
    );
  }

  Widget _buildFolderList(String userId, ThemeData theme) {
    final db = context.read<LocalDatabaseService>();
    return StreamBuilder<List<Folder>>(
      stream: db.watchAllFolders(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!
            .where((item) => item.name.toLowerCase().contains(_searchQuery))
            .toList();
        if (items.isEmpty) return _buildNoContentState('Folders', theme);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final folder = items[index];
            return FolderCard(
              folder: folder,
              onTap: () => context.go('/results-view/${folder.id}'),
              onDelete: () => _deleteFolder(folder.id),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryList(String userId, ThemeData theme) {
    final db = context.read<LocalDatabaseService>();
    return StreamBuilder<List<LocalSummary>>(
      stream: db.watchAllSummaries(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!
            .where((item) => item.title.toLowerCase().contains(_searchQuery))
            .toList();
        if (items.isEmpty) return _buildNoContentState('Summaries', theme);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final summary = items[index];
            return ItemCard(
              title: summary.title,
              subtitle: 'Summary',
              icon: Icons.article_outlined,
              onTap: () => context.go('/summary', extra: summary),
            );
          },
        );
      },
    );
  }

  Widget _buildQuizList(ThemeData theme) {
    return Consumer<QuizViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
        final items = viewModel.quizzes
            .where((item) => item.title.toLowerCase().contains(_searchQuery))
            .toList();
        if (items.isEmpty) return _buildNoContentState('Quizzes', theme);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final quiz = items[index];
            return ItemCard(
              title: quiz.title,
              subtitle: 'Quiz', 
              icon: Icons.quiz_outlined,
              onTap: () => context.go('/quiz', extra: quiz),
            );
          },
        );
      },
    );
  }

  Widget _buildFlashcardList(String userId, ThemeData theme) {
    final db = context.read<LocalDatabaseService>();
    return StreamBuilder<List<LocalFlashcardSet>>(
      stream: db.watchAllFlashcardSets(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!
            .where((item) => item.title.toLowerCase().contains(_searchQuery))
            .toList();
        if (items.isEmpty) return _buildNoContentState('Flashcards', theme);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final flashcardSet = items[index];
            return ItemCard(
              title: flashcardSet.title,
              subtitle: 'Flashcards', 
              icon: Icons.style_outlined,
              onTap: () => context.go('/flashcards', extra: flashcardSet),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteFolder(String folderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: const Text('This will delete the folder and all its contents. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Guard against async gaps
      if (mounted) {
        await context.read<LocalDatabaseService>().deleteFolder(folderId);
      }
    }
  }  

  Widget _buildLoggedOutView(ThemeData theme) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 24),
          Text('Please Log In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Log in to see your saved content.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNoContentState(String type, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            Text('No $type Found', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text(
              'Tap the + button to create some!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
