import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new merged account profile screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/account-profile');
    });

    // Show loading while redirecting
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
