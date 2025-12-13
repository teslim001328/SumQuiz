import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../services/subscription_service.dart';

class UpgradeDialog extends StatelessWidget {
  final String featureName;

  const UpgradeDialog({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upgrade to Pro to use $featureName'),
      content: const Text(
          'You have reached your daily limit for this feature. Upgrade to Pro for unlimited access.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(); // Close dialog first to avoid overlap

            final subscriptionService = context.read<SubscriptionService?>();
            if (subscriptionService != null) {
              try {
                final result = await subscriptionService.presentPaywall();
                if (result == PaywallResult.purchased) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Welcome to Pro! 🎉')),
                    );
                  }
                }
              } catch (e) {
                // Ignore or log
              }
            }
          },
          child: const Text('Upgrade'),
        ),
      ],
    );
  }
}
