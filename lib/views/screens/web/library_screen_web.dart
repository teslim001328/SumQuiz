import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/models/library_item.dart';
import 'package:sumquiz/services/firestore_service.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/view_models/quiz_view_model.dart';
import 'package:sumquiz/views/screens/summary_screen.dart';
import 'package:sumquiz/models/folder.dart';

class LibraryScreenWeb extends StatefulWidget {
  const LibraryScreenWeb({super.key});

  @override
  LibraryScreenWebState createState() => LibraryScreenWebState();
}

class LibraryScreenWebState extends State<LibraryScreenWeb>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isOfflineMode = false;
  String _searchQuery = '';
  Stream<List<LibraryItem>>? _allItemsStream;
  Stream<List<LibraryItem>>? _summariesStream;
  Stream<List<LibraryItem>>? _flashcardsStream;
  String? _userIdForStreams;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _localDb.init();
    _loadOfflineModePreference();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserModel?>(context);
    if (user != null && user.uid != _userIdForStreams) {
      _userIdForStreams = user.uid;
      _initializeStreams(user.uid);
      if (mounted) {
        Provider.of<QuizViewModel>(context, listen: false)
            .initializeForUser(user.uid);
      }
    }
  }

  void _initializeStreams(String userId) {
    // Reusing the stream logic from LibraryScreen for consistency
    final localSummaries = _localDb.watchAllSummaries(userId).map((list) => list
        .map((s) => LibraryItem(
            id: s.id,
            title: s.title,
            type: LibraryItemType.summary,
            timestamp: Timestamp.fromDate(s.timestamp)))
        .toList());

    final firestoreSummaries =
        _firestoreService.streamItems(userId, 'summaries');

    _summariesStream = Rx.combineLatest2<List<LibraryItem>, List<LibraryItem>,
        List<LibraryItem>>(
      localSummaries,
      firestoreSummaries.handleError((_) => <LibraryItem>[]),
      (local, cloud) {
        final ids = local.map((e) => e.id).toSet();
        return [...local, ...cloud.where((c) => !ids.contains(c.id))];
      },
    ).asBroadcastStream();

    final localFlashcards = _localDb.watchAllFlashcardSets(userId).map((list) =>
        list
            .map((f) => LibraryItem(
                id: f.id,
                title: f.title,
                type: LibraryItemType.flashcards,
                timestamp: Timestamp.fromDate(f.timestamp)))
            .toList());

    final firestoreFlashcards =
        _firestoreService.streamItems(userId, 'flashcards');

    _flashcardsStream = Rx.combineLatest2<List<LibraryItem>, List<LibraryItem>,
        List<LibraryItem>>(
      localFlashcards,
      firestoreFlashcards.handleError((_) => <LibraryItem>[]),
      (local, cloud) {
        final ids = local.map((e) => e.id).toSet();
        return [...local, ...cloud.where((c) => !ids.contains(c.id))];
      },
    ).asBroadcastStream();

    final localQuizzes = _localDb.watchAllQuizzes(userId).map((list) => list
        .map((q) => LibraryItem(
            id: q.id,
            title: q.title,
            type: LibraryItemType.quiz,
            timestamp: Timestamp.fromDate(q.timestamp)))
        .toList());

    _allItemsStream = Rx.combineLatest3<List<LibraryItem>, List<LibraryItem>,
            List<LibraryItem>, List<LibraryItem>>(
        _summariesStream!, _flashcardsStream!, localQuizzes,
        (summaries, flashcards, quizzes) {
      final all = [...summaries, ...flashcards, ...quizzes];
      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return all;
    }).asBroadcastStream();
  }

  void _onSearchChanged() =>
      setState(() => _searchQuery = _searchController.text.toLowerCase());

  Future<void> _loadOfflineModePreference() async {
    final isOffline = await _localDb.isOfflineModeEnabled();
    if (mounted) setState(() => _isOfflineMode = isOffline);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    // Desktop Layout: Sidebar + Main Content Area
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Light gray-blue web bg
      body: Row(
        children: [
          // Sidebar (could be part of shell, but here we can customize filtering)
          _buildWebSidebar(),
          // Main Content
          Expanded(
            child: user == null
                ? const Center(child: Text("Please Log In"))
                : _buildWebMainContent(user),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text('Library',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E))),
          const SizedBox(height: 32),
          _buildSidebarTab(0, 'Folders', Icons.folder_open),
          _buildSidebarTab(1, 'All Content', Icons.dashboard_outlined),
          _buildSidebarTab(2, 'Summaries', Icons.article_outlined),
          _buildSidebarTab(3, 'Quizzes', Icons.quiz_outlined),
          _buildSidebarTab(4, 'Flashcards', Icons.style_outlined),
        ],
      ),
    );
  }

  Widget _buildSidebarTab(int index, String title, IconData icon) {
    final bool isSelected = _tabController.index == index;
    return InkWell(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // Subtle background only when selected
          color: isSelected
              ? const Color(0xFF1A237E).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? const Color(0xFF1A237E) : Colors.grey[600],
                size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF1A237E) : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebMainContent(UserModel user) {
    return Column(
      children: [
        _buildWebHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics:
                const NeverScrollableScrollPhysics(), // Disable swipe on web
            children: [
              _buildFolderGrid(user.uid),
              _buildCombinedGrid(user.uid),
              _buildLibraryGrid(user.uid, 'summaries', _summariesStream),
              _buildQuizGrid(user.uid),
              _buildLibraryGrid(user.uid, 'flashcards', _flashcardsStream),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search your library...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateOptions(context),
            icon: const Icon(Icons.add),
            label: const Text("Create New"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderGrid(String userId) {
    return FutureBuilder<List<Folder>>(
      future: _localDb.getAllFolders(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final folders = snapshot.data ?? [];
        return GridView.builder(
          padding: const EdgeInsets.all(32),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 1.2,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return _buildWebCard(
              title: folder.name,
              subtitle: 'Folder',
              icon: Icons.folder,
              color: Colors.amber,
              onTap: () => context.push('/library/results-view/${folder.id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildCombinedGrid(String userId) {
    return StreamBuilder<List<LibraryItem>>(
      stream: _allItemsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        final filtered = items
            .where((i) => i.title.toLowerCase().contains(_searchQuery))
            .toList();
        return _buildContentGrid(filtered, userId);
      },
    );
  }

  Widget _buildLibraryGrid(
      String userId, String type, Stream<List<LibraryItem>>? stream) {
    return StreamBuilder<List<LibraryItem>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildContentGrid(snapshot.data!, userId);
      },
    );
  }

  Widget _buildQuizGrid(String userId) {
    return Consumer<QuizViewModel>(
      builder: (context, vm, _) {
        final items = vm.quizzes
            .map((q) => LibraryItem(
                id: q.id,
                title: q.title,
                type: LibraryItemType.quiz,
                timestamp: Timestamp.fromDate(q.timestamp)))
            .toList();
        return _buildContentGrid(items, userId);
      },
    );
  }

  Widget _buildContentGrid(List<LibraryItem> items, String userId) {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        childAspectRatio: 1.5,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        IconData icon;
        Color color;
        String typeName;
        switch (item.type) {
          case LibraryItemType.summary:
            icon = Icons.article;
            color = Colors.blue;
            typeName = 'Summary';
            break;
          case LibraryItemType.quiz:
            icon = Icons.quiz;
            color = Colors.green;
            typeName = 'Quiz';
            break;
          case LibraryItemType.flashcards:
            icon = Icons.style;
            color = Colors.orange;
            typeName = 'Flashcards';
            break;
        }

        return _buildWebCard(
          title: item.title,
          subtitle: typeName,
          icon: icon,
          color: color,
          onTap: () {
            // Navigation logic same as mobile
            if (item.type == LibraryItemType.summary) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SummaryScreen(summary: null)));
              // ideally fetch summary
            } else if (item.type == LibraryItemType.quiz) {
              // fetch quiz
            }
            // For now, placeholder or push with ID if route expects it
          },
        );
      },
    );
  }

  Widget _buildWebCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const Spacer(),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(subtitle,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
    );
  }

  void _showCreateOptions(BuildContext context) {
    // Show dialog instead of bottom sheet on web
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Create New Content",
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.article, color: Colors.blue),
                  title: const Text('Summary'),
                  onTap: () => context.push('/create'),
                ),
                ListTile(
                  leading: const Icon(Icons.quiz, color: Colors.green),
                  title: const Text('Quiz'),
                  onTap: () => context.push('/create'),
                ),
                ListTile(
                  leading: const Icon(Icons.style, color: Colors.orange),
                  title: const Text('Flashcards'),
                  onTap: () => context.push('/create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
