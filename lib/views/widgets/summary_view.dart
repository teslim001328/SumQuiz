import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

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
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA), // Paper-like background
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                    height: 1.2,
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
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        Colors.indigo.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                '#$tag',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo[800],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 32),
                SelectableText(
                  content,
                  style: GoogleFonts.merriweather(
                    fontSize: 16,
                    height: 1.8,
                    color: const Color(0xFF333333),
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
                color: Colors.white.withValues(alpha: 0.8), // Glass-like bar
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(width: 8),
                if (onSave != null) ...[
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'Save',
                      icon: Icons.bookmark_border_rounded,
                      onPressed: onSave,
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
                icon: const Icon(Icons.psychology_alt, color: Colors.white),
                label: Text("Generate Quiz from Summary",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF1A237E).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
      VoidCallback? onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: const Color(0xFF1A237E)),
      label: Text(label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: const Color(0xFF1A237E))),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
