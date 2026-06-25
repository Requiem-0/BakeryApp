import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/network/api_client.dart';
import 'core/storage/logo_cache.dart';
import 'core/storage/token_storage.dart';
import 'core/brandkit/app_theme.dart';
import 'core/brandkit/theme_provider.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/businesses/data/repositories/business_repository.dart';
import 'features/businesses/presentation/providers/business_provider.dart';
import 'features/catalogue/data/models/product.dart';
import 'features/catalogue/data/repositories/product_repository.dart';
import 'features/catalogue/presentation/providers/catalogue_provider.dart';
import 'features/cart/data/repositories/cart_repository.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/favourites/presentation/providers/favourites_provider.dart';
import 'features/address/presentation/providers/address_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/orders/data/repositories/order_repository.dart';
import 'features/orders/presentation/providers/order_provider.dart';
import 'core/navigation/nav_provider.dart';
import 'core/navigation/app_router.dart';
import 'core/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide the system status bar (clock / battery / notifications) so the
  // app extends edge-to-edge at the top. Keep the bottom system nav so
  // Android users still have back/home/recents. No-op on Web.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.bottom],
  );

  // ── Firebase + Crashlytics ──────────────────────────────────────
  // Wrapped in try/catch so dev machines that don't have a
  // google-services.json yet (the file is gitignored and lives only
  // on the build machine + CI secret store) can still run the app.
  // Without Firebase, exceptions just go to debugPrint as before.
  var crashlyticsReady = false;
  try {
    await Firebase.initializeApp();
    if (!kIsWeb) {
      // Crashlytics has no web SDK — only collect on native.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      crashlyticsReady = true;
    }
  } catch (e) {
    debugPrint('⚠️ Firebase init skipped (no config?): $e');
  }

  // Fallback Flutter error handler when Crashlytics isn't wired —
  // still surfaces the exception in the log so devs can see it.
  if (!crashlyticsReady) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('🚨 GLOBAL ERROR: ${details.exception}\n${details.stack}');
    };
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  final authRepository = AuthRepository(apiClient: apiClient);
  final authProvider = AuthProvider(
    repository: authRepository,
    tokenStorage: tokenStorage,
  );
  apiClient.onUnauthorized = authProvider.handleUnauthorized;
  authProvider.bootstrap().catchError((e, st) {
    debugPrint('🚨 Auth bootstrap failed: $e\n$st');
  });

  final router = createRouter(authProvider);

  final productRepository = ProductRepository(
    apiClient: apiClient,
    businessId: AppConstants.bakeryBusinessId,
  );
  final catalogueProvider =
      CatalogueProvider(repository: productRepository);
  catalogueProvider.bootstrap().catchError((e, st) {
    debugPrint('🚨 Catalogue bootstrap failed: $e\n$st');
  });

  final businessRepository = BusinessRepository(apiClient: apiClient);
  final businessProvider =
      BusinessProvider(repository: businessRepository);

  // Pre-loads the logo cached on disk from the previous run so the
  // splash can render it immediately on cold boot. The network refresh
  // fires later (via the BusinessProvider listener below).
  final logoCache = LogoCacheService();
  await logoCache.loadCached();

  businessProvider.addListener(() {
    final b = businessProvider.current;
    if (b != null) {
      AppConstants.applyBranding(
        appName: b.businessName,
        currency: b.admin.currency,
      );
      // Re-download the logo whenever the business resolves with a new
      // URL. ensureCached is a no-op when the on-disk cache already
      // matches, so this is cheap on hot launches.
      final logoUrl = AppConstants.resolveImageUrl(b.logo);
      if (logoUrl != null) {
        logoCache.ensureCached(logoUrl);
      }
    }
  });
  businessProvider.bootstrap(
    currentBusinessId: AppConstants.bakeryBusinessId,
  ).catchError((e, st) {
    debugPrint('🚨 Business bootstrap failed: $e\n$st');
  });

  final orderRepository = OrderRepository(apiClient: apiClient);
  final orderProvider = OrderProvider(
    repository: orderRepository,
    // Resolves a productId to the catalogue's full Product. OrderProvider
    // uses this to patch /my-orders entries — substituting Rs 0 line
    // prices with the catalogue's display price (cheapest variant) and
    // hydrating addon names/prices when the backend stored only ids.
    // Returns null when the catalogue hasn't bootstrapped yet or the
    // productId is unknown; enrichment just no-ops in that case.
    productResolver: (productId) {
      for (final api in catalogueProvider.products) {
        if (api.id == productId) {
          return Product.fromApi(api);
        }
      }
      return null;
    },
  );

  final cartRepository = CartRepository(apiClient: apiClient);
  final cartProvider = CartProvider(
    repository: cartRepository,
    isAuthenticated: () => authProvider.isAuthenticated,
    // Resolves cart-line productIds to fully-populated Products (with
    // adminId/variantItems/addons) by looking them up in the loaded
    // catalogue. Until the catalogue finishes its bootstrap this
    // returns null and the cart falls back to a thin Product built
    // from the cart-line's inline fields — still renderable.
    productResolver: (id) {
      for (final api in catalogueProvider.products) {
        if (api.id == id) return Product.fromApi(api);
      }
      return null;
    },
    // Per-order service charge straight from the business config (e.g.
    // Breaking Bread returns `orderChargePerOrder: 20`). Falls back to
    // 0 if no business has loaded yet — never assumes a hardcoded fee.
    serviceChargeResolver: () =>
        (businessProvider.current?.orderChargePerOrder ?? 0).toDouble(),
  );
  // Re-notify the cart whenever the business changes so the displayed
  // total in the cart summary updates with the live service charge.
  businessProvider.addListener(() {
    cartProvider.serviceChargeResolver = () =>
        (businessProvider.current?.orderChargePerOrder ?? 0).toDouble();
  });
  // When the catalogue finishes loading after the cart already hydrated,
  // upgrade any thin cart Products (no autoDiscount / variants / addons)
  // to their full catalogue versions. Without this, the discount badge
  // and the receipt's discount row silently come up empty.
  catalogueProvider.addListener(cartProvider.rehydrateProducts);
  // Restore any locally-persisted cart BEFORE backend bootstrap fires,
  // so guests (and authed users with a slow network) see their items
  // immediately on app start instead of an empty cart. Authed
  // bootstrap will overwrite this with the server-canonical cart.
  cartProvider.tryLoadLocalCart().catchError((e, st) {
    debugPrint('🚨 Cart local restore failed: $e\n$st');
  });
  cartProvider.bootstrap().catchError((e, st) {
    debugPrint('🚨 Cart bootstrap failed: $e\n$st');
  });

  final addressProvider = AddressProvider(apiClient: apiClient);
  final notificationProvider = NotificationProvider(apiClient: apiClient);
  // Refresh authed-only data on login, clear on logout. Tracks the last
  // observed auth flag so we only fire on TRANSITIONS — AuthProvider
  // notifies multiple times per flow (isBusy flips, errorMessage set,
  // then status). Initialize to the CURRENT auth state at attach time,
  // not null — otherwise the first notify (often `isBusy = true` when
  // the user taps Login, while status is still unauthenticated) reads
  // as a null → false transition and wipes the guest cart before
  // status even flips to authenticated.
  bool lastAuthState = authProvider.isAuthenticated;
  authProvider.addListener(() {
    final isAuth = authProvider.isAuthenticated;
    if (lastAuthState == isAuth) return;
    lastAuthState = isAuth;

    if (isAuth) {
      addressProvider.refresh().catchError((e, st) {
        debugPrint('🚨 Address refresh failed: $e\n$st');
      });
      notificationProvider.refresh().catchError((e, st) {
        debugPrint('🚨 Notification refresh failed: $e\n$st');
      });
      orderProvider.fetchOrders().catchError((e, st) {
        debugPrint('🚨 Order fetch failed: $e\n$st');
      });
      cartProvider.bootstrap().catchError((e, st) {
        debugPrint('🚨 Cart refresh failed: $e\n$st');
      });
    } else {
      addressProvider.clear();
      notificationProvider.clear();
      orderProvider.clear();
      cartProvider.clear().catchError((e, st) {
        debugPrint('🚨 Cart clear failed: $e\n$st');
      });
    }
  });

  runApp(App(
    router: router,
    apiClient: apiClient,
    authProvider: authProvider,
    catalogueProvider: catalogueProvider,
    businessProvider: businessProvider,
    orderProvider: orderProvider,
    cartProvider: cartProvider,
    addressProvider: addressProvider,
    notificationProvider: notificationProvider,
    logoCache: logoCache,
  ));
}

class App extends StatelessWidget {
  final GoRouter router;
  final ApiClient apiClient;
  final AuthProvider authProvider;
  final CatalogueProvider catalogueProvider;
  final BusinessProvider businessProvider;
  final OrderProvider orderProvider;
  final CartProvider cartProvider;
  final AddressProvider addressProvider;
  final NotificationProvider notificationProvider;
  final LogoCacheService logoCache;

  const App({
    super.key,
    required this.router,
    required this.apiClient,
    required this.authProvider,
    required this.catalogueProvider,
    required this.businessProvider,
    required this.orderProvider,
    required this.cartProvider,
    required this.addressProvider,
    required this.notificationProvider,
    required this.logoCache,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CatalogueProvider>.value(
            value: catalogueProvider),
        ChangeNotifierProvider<BusinessProvider>.value(
            value: businessProvider),
        ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ChangeNotifierProvider(create: (_) => FavouritesProvider()),
        ChangeNotifierProvider<AddressProvider>.value(value: addressProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
            value: notificationProvider),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<LogoCacheService>.value(value: logoCache),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeProvider>().mode;
          final isDark = themeMode == ThemeMode.dark;

          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                isDark ? Brightness.dark : Brightness.light,
          ));

          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
