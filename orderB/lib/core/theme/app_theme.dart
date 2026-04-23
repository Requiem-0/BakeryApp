import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_text_styles.dart';

/// Material theme wiring all brand tokens.
final class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.darkBrown,
          onPrimary: AppColors.cream,
          secondary: AppColors.caramel,
          onSecondary: AppColors.white,
          surface: AppColors.warmWhite,
          onSurface: AppColors.text,
          error: AppColors.terracotta,
        ),
        scaffoldBackgroundColor: AppColors.warmWhite,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.darkBrown),
          displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.darkBrown),
          headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.darkBrown),
          headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.darkBrown),
          headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.darkBrown),
          titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.darkBrown),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.text),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
          bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          labelMedium: AppTextStyles.label.copyWith(color: AppColors.textLight),
          labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.warmWhite,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.darkBrown),
          titleTextStyle: AppTextStyles.headlineLarge.copyWith(color: AppColors.darkBrown),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkBrown,
            foregroundColor: AppColors.cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusL),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            textStyle: AppTextStyles.buttonPrimary,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkBrown,
            side: const BorderSide(color: AppColors.darkBrown, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusM),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.softBrown,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusS),
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.darkBrown;
              }
              return AppColors.beige;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.cream;
              return AppColors.softBrown;
            }),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.darkBrown;
              }
              return AppColors.beige;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.cream;
              return AppColors.softBrown;
            }),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDecorations.radiusML)),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.darkBrown;
              }
              return AppColors.beige;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.cream;
              return AppColors.softBrown;
            }),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDecorations.radiusS)),
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusM),
            borderSide: const BorderSide(color: AppColors.beige, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusM),
            borderSide: const BorderSide(color: AppColors.beige, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusM),
            borderSide: const BorderSide(color: AppColors.caramel, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        dividerColor: AppColors.beige,
        dividerTheme: const DividerThemeData(
          color: AppColors.beige,
          thickness: 1,
          space: 0,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppDecorations.radiusCard)),
            side: BorderSide(color: AppColors.beige),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.golden,
          labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusSM),
            side: BorderSide.none,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDecorations.radiusCard)),
          ),
        ),
        extensions: <ThemeExtension<dynamic>>[
          AppThemeExtension(
            productImageGradient: AppColors.productImageGradient,
            primaryGradient: AppColors.primaryGradient,
            heroGradient: AppColors.heroGradient,
            receiptStyle: AppTextStyles.receipt.copyWith(color: AppColors.text),
          ),
        ],
      );

  // ─── Dark Theme ─────────────────────────────────────────────
  static const _darkSurface = Color(0xFF1A1412);
  static const _darkCard = Color(0xFF251E1A);
  static const _darkDivider = Color(0xFF3A302A);

  static const _darkOnSurface = AppColors.cream;
  static const _darkOnSurfaceVariant = Color(0xFF9A8B7D);

  static ThemeData get dark => light.copyWith(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.golden,
          onPrimary: AppColors.darkBrown,
          secondary: AppColors.caramel,
          onSecondary: AppColors.darkBrown,
          surface: _darkSurface,
          onSurface: _darkOnSurface,
          error: AppColors.terracotta,
          onSurfaceVariant: _darkOnSurfaceVariant,
        ),
        scaffoldBackgroundColor: _darkSurface,
        cardColor: _darkCard,
        dividerColor: _darkDivider,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: AppTextStyles.displayLarge.copyWith(color: _darkOnSurface),
          displayMedium: AppTextStyles.displayMedium.copyWith(color: _darkOnSurface),
          headlineLarge: AppTextStyles.headlineLarge.copyWith(color: _darkOnSurface),
          headlineMedium: AppTextStyles.headlineMedium.copyWith(color: _darkOnSurface),
          headlineSmall: AppTextStyles.headlineSmall.copyWith(color: _darkOnSurface),
          titleLarge: AppTextStyles.titleLarge.copyWith(color: _darkOnSurface),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(color: _darkOnSurface),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(color: _darkOnSurface),
          bodySmall: AppTextStyles.bodySmall.copyWith(color: _darkOnSurfaceVariant),
          labelMedium: AppTextStyles.label.copyWith(color: _darkOnSurfaceVariant),
          labelSmall: AppTextStyles.labelSmall.copyWith(color: _darkOnSurfaceVariant),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _darkSurface,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.cream),
          titleTextStyle: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.cream,
          ),
        ),
        cardTheme: const CardThemeData(
          color: _darkCard,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppDecorations.radiusCard)),
            side: BorderSide(color: _darkDivider),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _darkDivider,
          thickness: 1,
          space: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDecorations.radiusCard)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusM),
            borderSide: const BorderSide(color: _darkDivider, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusM),
            borderSide: const BorderSide(color: _darkDivider, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusM),
            borderSide:
                const BorderSide(color: AppColors.golden, width: 1.5),
          ),
          hintStyle: AppTextStyles.bodyMedium
              .copyWith(color: const Color(0xFF9A8B7D)),
        ),
        extensions: <ThemeExtension<dynamic>>[
          AppThemeExtension(
            productImageGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A2220), Color(0xFF352A24)],
            ),
            primaryGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.golden, AppColors.caramel],
            ),
            heroGradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2220), Color(0xFF352A24), Color(0xFF3D302A)],
              stops: [0.0, 0.5, 1.0],
            ),
            receiptStyle: AppTextStyles.receipt.copyWith(color: _darkOnSurface),
          ),
        ],
      );
}

/// Custom theme extension for properties not supported by default ThemeData.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Gradient productImageGradient;
  final Gradient primaryGradient;
  final Gradient heroGradient;
  final TextStyle receiptStyle;

  const AppThemeExtension({
    required this.productImageGradient,
    required this.primaryGradient,
    required this.heroGradient,
    required this.receiptStyle,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Gradient? productImageGradient,
    Gradient? primaryGradient,
    Gradient? heroGradient,
    TextStyle? receiptStyle,
  }) {
    return AppThemeExtension(
      productImageGradient: productImageGradient ?? this.productImageGradient,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      heroGradient: heroGradient ?? this.heroGradient,
      receiptStyle: receiptStyle ?? this.receiptStyle,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
      covariant ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      productImageGradient:
          Gradient.lerp(productImageGradient, other.productImageGradient, t)!,
      primaryGradient:
          Gradient.lerp(primaryGradient, other.primaryGradient, t)!,
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
      receiptStyle: TextStyle.lerp(receiptStyle, other.receiptStyle, t)!,
    );
  }
}
