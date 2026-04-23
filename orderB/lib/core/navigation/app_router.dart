import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../features/catalogue/data/models/product.dart';
import 'app_shell.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/catalogue/presentation/pages/product_detail_screen.dart';
import '../../features/cart/presentation/pages/cart_screen.dart';
import '../../features/checkout/presentation/pages/checkout_screen.dart';
import '../../features/checkout/presentation/pages/order_success_screen.dart';
import '../../features/orders/data/models/placed_order.dart';
import '../../features/orders/presentation/pages/order_tracking_screen.dart';
import '../../features/orders/presentation/pages/recent_orders_screen.dart';
import '../../features/favourites/presentation/pages/favourites_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/profile_sub_screens.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _favouritesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'favourites');
final GlobalKey<NavigatorState> _cartNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'cart');
final GlobalKey<NavigatorState> _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  errorBuilder: (context, state) => const _RouteErrorScreen(
    title: 'Page Not Found',
    message: "We couldn't find the page you're looking for.",
  ),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'product',
                  builder: (context, state) {
                    final product = state.extra as Product?;
                    if (product == null) return const _RouteErrorScreen();
                    return ProductDetailScreen(product: product);
                  },
                ),
                GoRoute(
                  path: 'recent_orders',
                  builder: (context, state) => const RecentOrdersScreen(),
                ),
              ],
            ),
          ],
        ),

        // Branch 1: Favourites
        StatefulShellBranch(
          navigatorKey: _favouritesNavigatorKey,
          routes: [
            GoRoute(
              path: '/favourites',
              builder: (context, state) => const FavouritesScreen(),
              routes: [
                GoRoute(
                  path: 'product',
                  builder: (context, state) {
                    final product = state.extra as Product?;
                    if (product == null) return const _RouteErrorScreen();
                    return ProductDetailScreen(product: product);
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 2: Cart & Checkout flow
        StatefulShellBranch(
          navigatorKey: _cartNavigatorKey,
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
              routes: [
                GoRoute(
                  path: 'checkout',
                  builder: (context, state) => const CheckoutScreen(),
                  routes: [
                    GoRoute(
                      path: 'success',
                      builder: (context, state) {
                        final order = state.extra as PlacedOrder?;
                        if (order == null) return const _RouteErrorScreen();
                        return OrderSuccessScreen(order: order);
                      },
                      routes: [
                        GoRoute(
                          path: 'tracking',
                          builder: (context, state) {
                            final order = state.extra as PlacedOrder?;
                            if (order == null) return const _RouteErrorScreen();
                            return OrderTrackingScreen(order: order);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Branch 3: Profile
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditProfileScreen(),
                ),
                GoRoute(
                  path: 'addresses',
                  builder: (context, state) => const SavedAddressesScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => const AddNewAddressScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'payments',
                  builder: (context, state) => const PaymentMethodsScreen(),
                ),
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) => const NotificationsScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'orders',
                  builder: (context, state) => const RecentOrdersScreen(),
                ),
                GoRoute(
                  path: 'favourites',
                  builder: (context, state) => const FavouritesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Fallback screen shown when a route is invalid (404) or when required
/// `state.extra` data is missing. Offers a one-tap return to home.
class _RouteErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const _RouteErrorScreen({
    this.title = 'Something went wrong',
    this.message = "We couldn't load this page.",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Lottie.asset(
                  'assets/animations/error_404.json',
                  width: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.error_outline_rounded,
                    size: 96,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  while (context.canPop()) {
                    context.pop();
                  }
                  context.go('/home');
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
