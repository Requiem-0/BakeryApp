import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'nav_provider.dart';

/// SharedPreferences key for the last-active shell branch index.
/// Persisted on every nav tap so cold-start / hot-restart lands the
/// user back on the tab they were on instead of always defaulting to
/// Home. Read by [SplashScreen] when deciding where to go after the
/// auth + business bootstrap finishes.
const String lastBranchIndexKey = 'last_branch_index';

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
      // Persist for cold-start restore. Fire-and-forget — if the write
      // fails (e.g. disk full) the only consequence is the next cold
      // launch defaults to Home, which is the existing behavior.
      SharedPreferences.getInstance()
          .then((p) => p.setInt(lastBranchIndexKey, index));
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
