import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Hide provider's ChangeNotifierProvider from Riverpod to avoid clash with
// package:provider during the incremental migration. Phases 1-5 will replace
// MultiProvider entries one at a time; once the last legacy ChangeNotifier is
// gone, remove package:provider and this hide directive.
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
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
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
