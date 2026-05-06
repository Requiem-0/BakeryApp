import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/catalogue/data/repositories/product_repository.dart';
import 'features/catalogue/presentation/providers/catalogue_provider.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/favourites/presentation/providers/favourites_provider.dart';
import 'features/address/presentation/providers/address_provider.dart';
import 'core/navigation/nav_provider.dart';
import 'features/profile/presentation/providers/user_provider.dart';
import 'core/navigation/app_router.dart';
import 'core/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  final authRepository = AuthRepository(apiClient: apiClient);
  final authProvider = AuthProvider(
    repository: authRepository,
    tokenStorage: tokenStorage,
  );
  apiClient.onUnauthorized = authProvider.handleUnauthorized;
  authProvider.bootstrap();

  final productRepository = ProductRepository(apiClient: apiClient);
  final catalogueProvider =
      CatalogueProvider(repository: productRepository);
  catalogueProvider.bootstrap();

  runApp(App(
    authProvider: authProvider,
    catalogueProvider: catalogueProvider,
  ));
}

class App extends StatelessWidget {
  final AuthProvider authProvider;
  final CatalogueProvider catalogueProvider;

  const App({
    super.key,
    required this.authProvider,
    required this.catalogueProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CatalogueProvider>.value(
            value: catalogueProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavouritesProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeProvider>().mode;
          final isDark = themeMode == ThemeMode.dark;

          // Update status bar style based on theme
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
