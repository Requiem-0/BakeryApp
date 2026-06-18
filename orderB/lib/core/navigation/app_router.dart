import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../features/businesses/presentation/providers/business_provider.dart';
import '../../features/catalogue/data/models/product.dart';
import '../constants.dart';
import '../storage/logo_cache.dart';
import 'app_shell.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/catalogue/presentation/pages/product_detail_screen.dart';
import '../../features/cart/presentation/pages/cart_screen.dart';
import '../../features/checkout/presentation/pages/checkout_screen.dart';
import '../../features/checkout/presentation/pages/order_success_screen.dart';
import '../../features/orders/data/models/placed_order.dart';
import '../../features/orders/presentation/pages/recent_orders_screen.dart';
import '../../features/favourites/presentation/pages/favourites_screen.dart';
import '../../features/profile/presentation/pages/add_new_address_screen.dart';
import '../../features/profile/presentation/pages/change_password_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/saved_addresses_screen.dart';
import '../../features/profile/presentation/pages/settings_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/reset_password_screen.dart';
import '../../features/auth/presentation/pages/verify_email_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../brandkit/app_colors.dart';

/// Root navigator key. Exposed so non-widget code (AuthProvider's 401
/// handler, background notification taps, etc.) can grab a BuildContext
/// for toasts + navigation without threading one through every layer.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _favouritesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'favourites');
final GlobalKey<NavigatorState> _cartNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'cart');
final GlobalKey<NavigatorState> _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final authStatus = authProvider.status;
      final location = state.uri.toString();

      // While auth is bootstrapping, pin to splash.
      if (authStatus == AuthStatus.initial) {
        return location == '/splash' ? null : '/splash';
      }

      // Auth done but unauthenticated — boot the user off any page
      // that genuinely needs a session (their orders, addresses, saved
      // payments, checkout, etc.). The token clear from
      // handleUnauthorized has already flipped status and surfaced a
      // toast; this just makes sure the next paint isn't a 403'd
      // ghost of the screen they were on.
      //
      // Guest-friendly paths (/home, /favourites, /cart, /profile root,
      // and any /login or /register flow) are intentionally NOT in
      // this list — guests can browse, just not place orders or read
      // their personal data.
      if (authStatus == AuthStatus.unauthenticated) {
        const protectedPrefixes = [
          '/home/recent_orders',
          '/profile/orders',
          '/profile/addresses',
          '/profile/settings/change-password',
          '/cart/checkout',
        ];
        for (final prefix in protectedPrefixes) {
          if (location.startsWith(prefix)) return '/login';
        }
      }

      // Auth done — the SplashScreen itself drives the next push so it
      // can hold the screen a beat longer until the BusinessProvider
      // resolves (and the real bakery logo is loaded). The router used
      // to force /splash → /home here, which dismissed splash before
      // the business call returned and forced the emoji fallback.

      // Intentionally NO redirect when an authed user lands on a marketing
      // auth screen (/login, /register, ...). The old auto-redirect to
      // /home replaced the entire navigation stack the instant login
      // succeeded — which killed the screens' pop-back-to-previous-page
      // behavior. Each auth screen now owns its own post-success nav
      // (LoginScreen pops if `canPop`, else goes /home).

      return null;
    },
    errorBuilder: (context, state) => const _RouteErrorScreen(
      title: 'Page Not Found',
      message: "We couldn't find the page you're looking for.",
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final token = state.uri.queryParameters['token'];
          return VerifyEmailScreen(initialEmail: email, initialToken: token);
        },
      ),
      // Top-level success & tracking — not inside any branch, so going home fully dismisses them
      GoRoute(
        path: '/checkout/success',
        builder: (context, state) {
          final order = state.extra as PlacedOrder?;
          if (order == null) return const _RouteErrorScreen();
          return OrderSuccessScreen(order: order);
        },
      ),
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
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                    routes: [
                      GoRoute(
                        path: 'change-password',
                        builder: (context, state) =>
                            const ChangePasswordScreen(),
                      ),
                    ],
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
}

/// The bakery logo bundled with the build (last snapshot from the
/// backend, baked into the APK / web assets). Rendered as the splash
/// fallback when [LogoCacheService] hasn't yet warmed up — instant on
/// every platform, including web where the cache service is a no-op.
///
/// Only used on prod builds — the bundled JPG is the Breaking Bread
/// logo and would look wrong on dev/QA builds pointed at a different
/// business. Dev builds skip straight to the 🥐 emoji until the
/// LogoCacheService lands the dev business's actual logo.
class _SplashAssetLogo extends StatelessWidget {
  const _SplashAssetLogo();

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.useProd) {
      return const Center(
        child: Text('🥐', style: TextStyle(fontSize: 72)),
      );
    }
    return Image.asset(
      'assets/branding/bakery_logo.jpg',
      width: 140,
      height: 140,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Text('🥐', style: TextStyle(fontSize: 72)),
      ),
    );
  }
}

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

/// Splash with a job: wait for auth + business to resolve so the
/// bakery's actual logo is ready before the user blinks into the
/// home screen. 4s timer is the parachute for a hung backend.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _fallbackTimer;
  bool _navigated = false;

  // Cached refs so dispose() doesn't have to do an ancestor lookup
  // (illegal — the widget is already deactivated by then).
  BusinessProvider? _business;
  AuthProvider? _auth;

  @override
  void initState() {
    super.initState();
    _business = context.read<BusinessProvider>()..addListener(_maybeNavigate);
    _auth = context.read<AuthProvider>()..addListener(_maybeNavigate);
    _fallbackTimer = Timer(const Duration(seconds: 4), _maybeNavigate);
    // First-paint check, in case both already resolved before we
    // even got off the ground.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNavigate());
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _business?.removeListener(_maybeNavigate);
    _auth?.removeListener(_maybeNavigate);
    super.dispose();
  }

  void _maybeNavigate() {
    if (_navigated || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.initial) return;
    final bizState = context.read<BusinessProvider>().currentState;
    final isFallbackElapsed = _fallbackTimer?.isActive == false;
    final bizDone = bizState == BusinessLoadState.ready ||
        bizState == BusinessLoadState.error;
    if (!bizDone && !isFallbackElapsed) return;
    _navigated = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final business = context.watch<BusinessProvider>().current;
    // Logo fallback chain: on-disk cache → bundled asset → 🥐.
    // The emoji is a safety net you'll only see if the asset
    // bundling itself broke, in which case you have bigger
    // problems.
    final cachedLogoFile = context.watch<LogoCacheService>().file;
    final name = (business?.businessName.isNotEmpty == true)
        ? business!.businessName
        : AppConstants.appName;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo plate — logo fills the rounded square edge-to-edge
            // via BoxFit.cover + zero padding, so the JPG's own
            // backdrop never peeks out from behind it. The rounded
            // clip handles the corners; the shadow gives soft depth.
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkBrown.withValues(alpha: 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: cachedLogoFile != null
                  ? Image.file(
                      cachedLogoFile,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _SplashAssetLogo(),
                    )
                  : const _SplashAssetLogo(),
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
