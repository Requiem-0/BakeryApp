import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'nav_provider.dart';

/// Root app shell — manages bottom nav and screen stack via GoRouter.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    void onNavTap(int index) {
      HapticFeedback.selectionClick();
      if (index == 0 && index == navigationShell.currentIndex) {
        context.read<NavProvider>().triggerHomeTap();
      }
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}
