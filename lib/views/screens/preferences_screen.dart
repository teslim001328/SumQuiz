import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/providers/theme_provider.dart';

/// Modern preferences screen with enhanced visual design and additional options
/// Allows users to customize their app experience with theme, font size, and more
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Preferences',
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
                _buildDarkModeTile(themeProvider, theme),
                const Divider(height: 32),
                _buildFontSizeSelector(themeProvider, theme),
                const Divider(height: 32),
                _buildToggleOption(
                  context,
                  title: 'Notifications',
                  subtitle: 'Enable or disable app notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const Divider(height: 32),
                _buildToggleOption(
                  context,
                  title: 'Haptic Feedback',
                  subtitle: 'Enable vibration for interactions',
                  value: _hapticFeedbackEnabled,
                  onChanged: (value) {
                    setState(() {
                      _hapticFeedbackEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeTile(ThemeProvider themeProvider, ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Dark Mode', style: theme.textTheme.titleLarge),
      subtitle: Text('Switch between light and dark themes',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.textTheme.bodySmall?.color)),
      trailing: Switch(
        value: themeProvider.themeMode == ThemeMode.dark,
        onChanged: (value) {
          themeProvider.toggleTheme();
        },
        activeThumbColor: theme.colorScheme.onSurface,
        activeTrackColor: theme.colorScheme.secondaryContainer,
        inactiveThumbColor: theme.colorScheme.onSurface,
        inactiveTrackColor: theme.colorScheme.secondaryContainer,
      ),
    );
  }

  Widget _buildFontSizeSelector(ThemeProvider themeProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Size',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Adjust text size for better readability',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildFontSizeOption(themeProvider, 0, 'Small', 0.8, theme),
              _buildFontSizeOption(themeProvider, 1, 'Medium', 1.0, theme),
              _buildFontSizeOption(themeProvider, 2, 'Large', 1.2, theme),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFontSizeOption(ThemeProvider themeProvider, int index,
      String text, double scale, ThemeData theme) {
    final isSelected = _fontSizeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _fontSizeIndex = index;
            themeProvider.setFontScale(scale);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: theme.textTheme.titleLarge),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.textTheme.bodySmall?.color)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.colorScheme.onSurface,
        activeTrackColor: theme.colorScheme.secondaryContainer,
        inactiveThumbColor: theme.colorScheme.onSurface,
        inactiveTrackColor: theme.colorScheme.secondaryContainer,
      ),
    );
  }
}
