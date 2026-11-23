import 'package:flutter/material.dart';

/// "Achromatic ledger": no colour in the chrome, money in ink, one blue on the main data
/// element, green only on money coming in. Ground is a blue-grey (a cloud, a ledger page).
@immutable
class Ledger extends ThemeExtension<Ledger> {
  const Ledger({
    required this.ground,
    required this.surface,
    required this.raised,
    required this.active,
    required this.border,
    required this.rule,
    required this.control,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.hue,
    required this.positive,
    required this.negative,
    required this.dark,
  });

  final Color ground, surface, raised, active, border, rule, control, text, muted;
  final Color primary, onPrimary, hue, positive, negative;
  final bool dark;

  static const light = Ledger(
    ground: Color(0xFFF2F4F7),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFF7F8FA),
    active: Color(0xFFE5E5E5),
    border: Color(0xFFE6E6E6),
    rule: Color(0xFFF0F0F0),
    control: Color(0xFFD4D4D4),
    text: Color(0xFF0A0A0A),
    muted: Color(0xFF6B6B6B),
    primary: Color(0xFF141414),
    onPrimary: Color(0xFFFFFFFF),
    hue: Color(0xFF1D5FBF),
    positive: Color(0xFF2E7D32),
    negative: Color(0xFFC4242A),
    dark: false,
  );

  static const darkTheme = Ledger(
    ground: Color(0xFF000000),
    surface: Color(0xFF111111),
    raised: Color(0xFF1A1A1A),
    active: Color(0xFF2A2A2A),
    border: Color(0xFF2E2E2E),
    rule: Color(0xFF1C1C1C),
    control: Color(0xFF444444),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFB4B4B4),
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    hue: Color(0xFF6EA0F0),
    positive: Color(0xFF3FC07A),
    negative: Color(0xFFE5566F),
    dark: true,
  );

  static Ledger of(BuildContext context) => Theme.of(context).extension<Ledger>()!;

  /// A pale, stable tint per person (identity, not data).
  (Color bg, Color ink) personTint(String name) {
    final hue = (name.codeUnits.fold(0, (a, b) => a * 31 + b) % 360).toDouble();
    return dark
        ? (HSLColor.fromAHSL(1, hue, .35, .22).toColor(), HSLColor.fromAHSL(1, hue, .6, .8).toColor())
        : (HSLColor.fromAHSL(1, hue, .6, .92).toColor(), HSLColor.fromAHSL(1, hue, .6, .25).toColor());
  }

  @override
  Ledger copyWith() => this;

  @override
  Ledger lerp(Ledger? other, double t) => t < .5 ? this : (other ?? this);
}

const tabular = [FontFeature.tabularFigures()];

ThemeData buildTheme(Ledger l) {
  final base = ThemeData(
    brightness: l.dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: l.hue,
      brightness: l.dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: l.primary,
      onPrimary: l.onPrimary,
      surface: l.surface,
      onSurface: l.text,
      onSurfaceVariant: l.muted,
      outline: l.control,
      outlineVariant: l.border,
      error: l.negative,
      secondaryContainer: l.active,
      onSecondaryContainer: l.text,
      surfaceContainerHighest: l.raised,
    ),
  );
  final text = base.textTheme.apply(bodyColor: l.text, displayColor: l.text);
  final ctrl = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
  OutlineInputBorder field(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    extensions: [l],
    scaffoldBackgroundColor: l.ground,
    dividerColor: l.rule,
    dividerTheme: DividerThemeData(color: l.rule, thickness: 1, space: 1),
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      titleMedium: text.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: text.bodySmall?.copyWith(fontSize: 12, color: l.muted),
      labelMedium: text.labelMedium?.copyWith(fontSize: 12, color: l.muted, fontWeight: FontWeight.w400),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: l.ground,
      foregroundColor: l.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: l.text),
    ),
    cardTheme: CardThemeData(
      color: l.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: l.border)),
    ),
    listTileTheme: ListTileThemeData(iconColor: l.muted, textColor: l.text, minVerticalPadding: 10),
    iconTheme: IconThemeData(color: l.muted, size: 20),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: l.primary,
        foregroundColor: l.onPrimary,
        minimumSize: const Size(64, 44),
        shape: ctrl,
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: l.text, shape: ctrl)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: l.text, side: BorderSide(color: l.control), shape: ctrl),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: l.primary,
      foregroundColor: l.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: l.surface,
      selectedColor: l.active,
      side: BorderSide(color: l.border),
      shape: ctrl,
      showCheckmark: false,
      labelStyle: TextStyle(color: l.text, fontSize: 14),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: l.surface,
        selectedBackgroundColor: l.active,
        selectedForegroundColor: l.text,
        foregroundColor: l.muted,
        side: BorderSide(color: l.border),
        shape: ctrl,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: l.surface,
      indicatorColor: l.active,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, color: l.text)),
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? l.text : l.muted)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: l.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: TextStyle(color: l.muted),
      border: field(l.control),
      enabledBorder: field(l.control),
      focusedBorder: field(l.text, 1.5),
      errorBorder: field(l.negative),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: l.surface, showDragHandle: true),
    dialogTheme: DialogThemeData(backgroundColor: l.surface),
    datePickerTheme: DatePickerThemeData(backgroundColor: l.surface),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: l.text),
    snackBarTheme: SnackBarThemeData(backgroundColor: l.primary, contentTextStyle: TextStyle(color: l.onPrimary)),
  );
}

/// Label above the field (no floating labels).
class Labeled extends StatelessWidget {
  const Labeled(this.label, this.child, {super.key});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          child,
        ],
      );
}

/// Round initial in the person's own pale tint.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {super.key, this.size = 32});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, ink) = Ledger.of(context).personTint(name);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(color: ink, fontSize: size * .42, fontWeight: FontWeight.w500),
      ),
    );
  }
}
