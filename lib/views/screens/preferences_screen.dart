import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/providers/theme_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  int _fontSizeIndex = 1;
  bool _notificationsEnabled = true;
  bool _hapticFeedbackEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Preferences',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    _buildSectionHeader('Appearance')
                        .animate()
                        .fadeIn()
                        .slideX(),
                    const SizedBox(height: 16),
                    _buildGlassSection(
                      children: [
                        _buildDarkModeTile(themeProvider),
                        _buildDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: _buildFontSizeSelector(themeProvider),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Interaction')
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideX(),
                    const SizedBox(height: 16),
                    _buildGlassSection(
                      children: [
                        _buildToggleOption(
                          context,
                          title: 'Notifications',
                          value: _notificationsEnabled,
                          icon: Icons.notifications_none,
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildToggleOption(
                          context,
                          title: 'Haptic Feedback',
                          value: _hapticFeedbackEnabled,
                          icon: Icons.vibration,
                          onChanged: (value) {
                            setState(() {
                              _hapticFeedbackEnabled = value;
                            });
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGlassSection({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildDarkModeTile(ThemeProvider themeProvider) {
    return SwitchListTile(
      title: Text('Dark Mode',
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purpleAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.dark_mode_outlined,
            color: Colors.purpleAccent, size: 20),
      ),
      value: themeProvider.themeMode == ThemeMode.dark,
      onChanged: (value) => themeProvider.toggleTheme(),
      activeTrackColor: Colors.purpleAccent,
      hoverColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _buildFontSizeSelector(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.format_size,
                  color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Text('Font Size',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFontSizeOption(themeProvider, 0, 'Small', 0.8),
              _buildFontSizeOption(themeProvider, 1, 'Medium', 1.0),
              _buildFontSizeOption(themeProvider, 2, 'Large', 1.2),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFontSizeOption(
      ThemeProvider themeProvider, int index, String text, double scale) {
    final isSelected = _fontSizeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _fontSizeIndex = index;
            themeProvider.setFontScale(scale);
          });
        },
        child: AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title,
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.pinkAccent, size: 20),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: Colors.pinkAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
