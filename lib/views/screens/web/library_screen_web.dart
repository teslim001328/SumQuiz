import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/models/library_item.dart';
import 'package:sumquiz/services/firestore_service.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/view_models/quiz_view_model.dart';
import 'package:sumquiz/views/screens/summary_screen.dart';
import 'package:sumquiz/models/folder.dart';
import 'package:sumquiz/views/widgets/web/glass_card.dart';
import 'package:sumquiz/views/widgets/web/neon_button.dart';
import 'package:sumquiz/views/widgets/web/particle_background.dart';

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

  String _searchQuery = '';
  Stream<List<LibraryItem>>? _allItemsStream;
  Stream<List<LibraryItem>>? _summariesStream;
  Stream<List<LibraryItem>>? _flashcardsStream;
  String? _userIdForStreams;
  int _hoveredCard = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _localDb.init();
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
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
            right: 200,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.2),
                      const Color(0xFF6366F1).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: user == null
                    ? const Center(
                        child: Text(
                          "Please Log In",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      )
                    : _buildMainContent(user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return GlassCard(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      blur: 20,
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ).createShader(bounds),
              child: const Text(
                'Library',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildSidebarTab(0, 'Folders', Icons.folder_open),
            const SizedBox(height: 8),
            _buildSidebarTab(1, 'All Content', Icons.dashboard_outlined),
            const SizedBox(height: 8),
            _buildSidebarTab(2, 'Summaries', Icons.article_outlined),
            const SizedBox(height: 8),
            _buildSidebarTab(3, 'Quizzes', Icons.quiz_outlined),
            const SizedBox(height: 8),
            _buildSidebarTab(4, 'Flashcards', Icons.style_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTab(int index, String title, IconData icon) {
    final isSelected = _tabController.index == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _tabController.animateTo(index)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: !isSelected ? Colors.white.withOpacity(0.03) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(UserModel user) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              margin: EdgeInsets.zero,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search your library...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          NeonButton(
            text: 'Create New',
            onPressed: () => context.push('/create'),
            icon: Icons.add,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            glowColor: const Color(0xFF6366F1),
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
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
        }
        final folders = snapshot.data ?? [];
        return _buildMasonryGrid(
          folders
              .map((f) => _LibraryCardData(
                    title: f.name,
                    subtitle: 'Folder',
                    icon: Icons.folder,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    onTap: () => context.push('/library/results-view/${f.id}'),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCombinedGrid(String userId) {
    return StreamBuilder<List<LibraryItem>>(
      stream: _allItemsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
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
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
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
    final cardData = items.map((item) {
      IconData icon;
      Gradient gradient;
      String typeName;
      switch (item.type) {
        case LibraryItemType.summary:
          icon = Icons.article;
          gradient = const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          );
          typeName = 'Summary';
          break;
        case LibraryItemType.quiz:
          icon = Icons.quiz;
          gradient = const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
          );
          typeName = 'Quiz';
          break;
        case LibraryItemType.flashcards:
          icon = Icons.style;
          gradient = const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFF97316)],
          );
          typeName = 'Flashcards';
          break;
      }

      return _LibraryCardData(
        title: item.title,
        subtitle: typeName,
        icon: icon,
        gradient: gradient,
        onTap: () {
          if (item.type == LibraryItemType.summary) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SummaryScreen(summary: null)));
          }
        },
      );
    }).toList();

    return _buildMasonryGrid(cardData);
  }

  Widget _buildMasonryGrid(List<_LibraryCardData> cards) {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredCard = index),
          onExit: (_) => setState(() => _hoveredCard = -1),
          child: _buildLibraryCard(
            card: card,
            isHovered: _hoveredCard == index,
            delay: index * 50,
          ),
        );
      },
    );
  }

  Widget _buildLibraryCard({
    required _LibraryCardData card,
    required bool isHovered,
    required int delay,
  }) {
    return GestureDetector(
      onTap: card.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..translate(0.0, isHovered ? -8.0 : 0.0)
          ..rotateZ(isHovered ? -0.01 : 0.0),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          margin: EdgeInsets.zero,
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: (card.gradient as LinearGradient)
                        .colors
                        .first
                        .withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: card.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (card.gradient as LinearGradient)
                          .colors
                          .first
                          .withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(card.icon, color: Colors.white, size: 32),
              ),
              const Spacer(),
              Text(
                card.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                card.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _LibraryCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  _LibraryCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}
