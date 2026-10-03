import 'package:flutter/material.dart';

/// Brand colours. Khaki and olive say "uniform"; saffron is the one loud
/// colour (like Strava's orange or Nike's volt): primary buttons, live data,
/// progress. Ink on saffron, never white, so it reads in bright sun.
class Brand {
  static const saffron = Color(0xFFFF7A00);
  static const saffronSoft = Color(0xFFFFE3CC);
  static const olive = Color(0xFF3B4420);
  static const oliveDeep = Color(0xFF232913);
  static const khaki = Color(0xFFC9B98F);
  static const khakiSoft = Color(0xFFE9E3CF);
  static const sand = Color(0xFFF6F2E8);
  static const ink = Color(0xFF1B1D12);
  static const muted = Color(0xFF6B6B5C);
  static const good = Color(0xFF2E7D32);
  static const bad = Color(0xFFC62828);
}

/// Big condensed numerals for times and distances, bundled so they work
/// offline. Latin digits only; Hindi text uses the phone's own font.
const numeralFont = 'BarlowCondensed';

TextStyle numerals(double size, {Color? color}) => TextStyle(
  fontFamily: numeralFont,
  fontSize: size,
  fontWeight: FontWeight.w800,
  height: 1,
  color: color,
  fontFeatures: const [FontFeature.tabularFigures()],
);

class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: Brand.olive,
      brightness: Brightness.light,
    ).copyWith(
      primary: Brand.saffron,
      onPrimary: Brand.ink,
      primaryContainer: Brand.saffronSoft,
      onPrimaryContainer: Brand.ink,
      secondary: Brand.olive,
      onSecondary: Colors.white,
      secondaryContainer: Brand.khakiSoft,
      onSecondaryContainer: Brand.ink,
      tertiaryContainer: const Color(0xFFFFE9A8),
      onTertiaryContainer: Brand.ink,
      surface: Brand.sand,
      onSurface: Brand.ink,
      onSurfaceVariant: Brand.muted,
      outline: const Color(0xFFB5B09C),
      outlineVariant: const Color(0xFFDAD5C0),
      error: Brand.bad,
      errorContainer: const Color(0xFFFAD4D0),
      onErrorContainer: Brand.ink,
    ),
    card: Colors.white,
  );

  /// Used on the run screen: true dark, saffron numbers, like a sports watch.
  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: Brand.olive,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Brand.saffron,
      onPrimary: Brand.ink,
      primaryContainer: const Color(0xFF5A3200),
      onPrimaryContainer: Colors.white,
      secondary: Brand.khaki,
      onSecondary: Brand.ink,
      secondaryContainer: const Color(0xFF3A3F28),
      onSecondaryContainer: Colors.white,
      surface: Brand.oliveDeep,
      onSurface: const Color(0xFFF3F0E4),
      onSurfaceVariant: const Color(0xFFB9B5A0),
      outline: const Color(0xFF7C7966),
      outlineVariant: const Color(0xFF45493A),
      error: const Color(0xFFFF8A80),
    ),
    card: const Color(0xFF2E341D),
  );

  static ThemeData _build(ColorScheme c, {required Color card}) {
    final base = ThemeData(colorScheme: c, useMaterial3: true);
    final text = base.textTheme
        .apply(bodyColor: c.onSurface, displayColor: c.onSurface)
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );
    const stadium = StadiumBorder();
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: c.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dividerTheme: DividerThemeData(color: c.outlineVariant, space: 24),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: stadium,
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: stadium,
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.outline, width: 1.5),
          textStyle: text.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brightness == Brightness.light
              ? Brand.olive
              : c.secondary,
          textStyle: text.titleSmall,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 2,
        shape: stadium,
        extendedTextStyle: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: stadium,
        side: BorderSide(color: c.outlineVariant),
        backgroundColor: card,
        selectedColor: c.brightness == Brightness.light
            ? Brand.olive
            : c.secondaryContainer,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: Colors.white),
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        elevation: 0,
        height: 72,
        indicatorColor: c.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 26,
            color: s.contains(WidgetState.selected)
                ? c.onSurface
                : c.onSurfaceVariant,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Brand.ink : c.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? c.primary : c.outlineVariant,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: Brand.olive,
          selectedForegroundColor: Colors.white,
          foregroundColor: c.onSurface,
          backgroundColor: card,
          textStyle: text.labelLarge,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
