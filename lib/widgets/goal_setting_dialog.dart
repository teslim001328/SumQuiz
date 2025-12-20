import 'package:flutter/material.dart';

class GoalSettingDialog extends StatefulWidget {
  final int currentGoal;

  const GoalSettingDialog({super.key, required this.currentGoal});

  @override
  State<GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends State<GoalSettingDialog> {
  late int _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Set Daily Goal', style: theme.textTheme.headlineSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many items would you like to complete each day?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [3, 5, 7, 10, 15, 20]
                .map((goal) => ChoiceChip(
                      label: Text('$goal items'),
                      selected: _selectedGoal == goal,
                      onSelected: (selected) {
                        setState(() {
                          _selectedGoal = selected ? goal : _selectedGoal;
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Or enter a custom goal:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _selectedGoal.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Custom goal',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  setState(() {
                    _selectedGoal = parsed;
                  });
                }
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: theme.textTheme.bodyLarge),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedGoal),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: Text('Save', style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}
