import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/theme_provider.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  int _fontSizeIndex = 1;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Preferences',
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
                _buildDarkModeTile(themeProvider, theme),
                const Divider(height: 32),
                _buildFontSizeSelector(themeProvider, theme),
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
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildFontSizeOption(ThemeProvider themeProvider, int index, String text, double scale, ThemeData theme) {
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
