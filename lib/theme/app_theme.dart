import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const primary = Color(0xFF004AC6);
  static const primaryContainer = Color(0xFF2563EB);
  static const secondary = Color(0xFF006C49);
  static const secondaryContainer = Color(0xFF6CF8BB);

  static ThemeData get light => _theme(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFFEEEFFF),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF00714D),
      tertiary: Color(0xFF525658),
      error: Color(0xFFBA1A1A),
      surface: Color(0xFFF8F9FF),
      onSurface: Color(0xFF0D1C2E),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFEFF4FF),
      surfaceContainer: Color(0xFFE6EEFF),
      surfaceContainerHigh: Color(0xFFDCE9FF),
      outline: Color(0xFF737686),
      outlineVariant: Color(0xFFC3C6D7),
    ),
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: Color(0xFFB4C5FF),
      onPrimary: Color(0xFF002A78),
      primaryContainer: Color(0xFF0A46BA),
      onPrimaryContainer: Color(0xFFDBE1FF),
      secondary: Color(0xFF4EDEA3),
      onSecondary: Color(0xFF003824),
      secondaryContainer: Color(0xFF005236),
      onSecondaryContainer: Color(0xFF6FFBBE),
      tertiary: Color(0xFFC4C7CA),
      error: Color(0xFFFFB4AB),
      surface: Color(0xFF0D1726),
      onSurface: Color(0xFFE6EEFF),
      surfaceContainerLowest: Color(0xFF08111E),
      surfaceContainerLow: Color(0xFF152236),
      surfaceContainer: Color(0xFF1A2940),
      surfaceContainerHigh: Color(0xFF233653),
      outline: Color(0xFF8D91A1),
      outlineVariant: Color(0xFF434655),
    ),
  );

  static ThemeData _theme({
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            height: 36 / 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.56,
            color: scheme.onSurface,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: scheme.onSurface,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
            color: scheme.onSurfaceVariant,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            letterSpacing: .6,
            color: scheme.onSurfaceVariant,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface.withValues(alpha: .94),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.primary),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: const StadiumBorder(),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : scheme.surfaceContainerLowest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        surfaceTintColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: .07),
        ),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .45),
      ),
    );
  }
}
