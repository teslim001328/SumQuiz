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
    return Column(
      children: [
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tags
                        .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer))
                        .toList(),
                  ),
                const Divider(height: 32),
                Text(content,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ),
        if (showActions) ...[
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      onPressed: onCopy,
                      label: const Text('Copy'))),
              if (onSave != null) ...[
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton.icon(
                        icon: const Icon(Icons.library_add),
                        onPressed: onSave,
                        label: const Text('Save'))),
              ],
            ],
          ),
          if (onGenerateQuiz != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onGenerateQuiz,
              icon: const Icon(Icons.psychology_alt_outlined),
              label: const Text("Generate Quiz from Summary"),
            ),
          ]
        ],
      ],
    );
  }
}
