import 'package:flutter/material.dart';

class SummaryView extends StatelessWidget {
  final String title;
  final String content;
  final List<String> tags;
  final VoidCallback? onCopy;
  final VoidCallback? onSave;
  final VoidCallback? onGenerateQuiz;
  final bool showActions;

  const SummaryView({
    super.key,
    required this.title,
    required this.content,
    required this.tags,
    this.onCopy,
    this.onSave,
    this.onGenerateQuiz,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: theme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: tags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '#$tag',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 32),
                SelectableText(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.8,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showActions) ...[
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Copy',
                    icon: Icons.copy_rounded,
                    onPressed: onCopy,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: theme.dividerColor),
                const SizedBox(width: 8),
                if (onSave != null) ...[
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'Save',
                      icon: Icons.bookmark_border_rounded,
                      onPressed: onSave,
                      theme: theme,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onGenerateQuiz != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onGenerateQuiz,
                icon: Icon(Icons.psychology_alt,
                    color: theme.colorScheme.onPrimary),
                label: Text("Generate Quiz from Summary",
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          ]
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String label,
      required IconData icon,
      VoidCallback? onPressed,
      required ThemeData theme}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: theme.colorScheme.primary),
      label: Text(label,
          style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
