import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/navigation_provider.dart';
import 'library_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'review_screen.dart';
import 'create_screen.dart';
import '../../models/user_model.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      const LibraryScreen(),
      const ReviewScreen(),
      const CreateScreen(),
      const ProgressScreen(),
      const ProfileScreen(),
    ];

    return Consumer<UserModel?>(
      builder: (context, userModel, child) {
        if (userModel == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Consumer<NavigationProvider>(
          builder: (context, navigationProvider, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Use BottomNavigationBar for narrow screens
                  return Scaffold(
                    body: widgetOptions
                        .elementAt(navigationProvider.selectedIndex),
                    bottomNavigationBar: BottomNavigationBar(
                      items: const <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Icon(Icons.book),
                          label: 'Library',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.school),
                          label: 'Review',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.add_circle_outline),
                          label: 'Create',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.show_chart),
                          label: 'Progress',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                      currentIndex: navigationProvider.selectedIndex,
                      onTap: (index) => navigationProvider.setIndex(index),
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: Theme.of(context).colorScheme.primary,
                      unselectedItemColor: Colors.grey,
                    ),
                  );
                } else {
                  // Use NavigationRail for wider screens
                  return Scaffold(
                    body: Row(
                      children: [
                        NavigationRail(
                          selectedIndex: navigationProvider.selectedIndex,
                          onDestinationSelected: (index) =>
                              navigationProvider.setIndex(index),
                          labelType: NavigationRailLabelType.all,
                          destinations: const <NavigationRailDestination>[
                            NavigationRailDestination(
                              icon: Icon(Icons.book),
                              label: Text('Library'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.school),
                              label: Text('Review'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.add_circle_outline),
                              label: Text('Create'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.show_chart),
                              label: Text('Progress'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.person),
                              label: Text('Profile'),
                            ),
                          ],
                        ),
                        const VerticalDivider(thickness: 1, width: 1),
                        Expanded(
                          child: widgetOptions
                              .elementAt(navigationProvider.selectedIndex),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
