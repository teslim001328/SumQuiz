import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AiToolsScreen extends StatelessWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 120.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('AI Tools',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                // Determine the number of columns based on the available width.
                final crossAxisCount =
                    (constraints.crossAxisExtent / 350).floor().clamp(1, 3);

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20.0,
                    mainAxisSpacing: 20.0,
                    childAspectRatio:
                        1.5, // Adjust this ratio to fit your card content
                  ),
                  delegate: SliverChildListDelegate(
                    AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: widget,
                        ),
                      ),
                      children: [
                        _buildFeatureCard(
                          context,
                          theme: theme,
                          icon: Icons.flash_on,
                          title: 'Generate Summary',
                          subtitle:
                              'Summarize any text, article, or document instantly.',
                          color: Colors.blueAccent,
                          onTap: () => context.push('/summary'),
                        ),
                        _buildFeatureCard(
                          context,
                          theme: theme,
                          icon: Icons.filter_none,
                          title: 'Flashcards',
                          subtitle:
                              'Create flashcards from any content to aid your learning.',
                          color: Colors.greenAccent,
                          onTap: () => context.push('/flashcards'),
                        ),
                        _buildFeatureCard(
                          context,
                          theme: theme,
                          icon: Icons.question_answer,
                          title: 'Generate Quiz',
                          subtitle:
                              'Create a quiz from any content to test your knowledge.',
                          color: Colors.purpleAccent,
                          onTap: () => context.push('/quiz'),
                        ),
                        _buildProFeatureCard(
                          context,
                          theme: theme,
                          icon: Icons.picture_as_pdf,
                          title: 'Quiz from PDF & Images',
                          subtitle:
                              'Upgrade to Pro to unlock generation from documents and photos.',
                          onTap: () => context.push('/subscription'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required ThemeData theme,
      required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.4),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center, // Center content vertically
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 16),
              Text(title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.8),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProFeatureCard(BuildContext context,
      {required ThemeData theme,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.yellow.shade700,
              width: 1.5,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.shade700.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: Colors.yellow.shade700),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('PRO',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
