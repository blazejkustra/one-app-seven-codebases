import 'package:flutter/widgets.dart';

/// Design tokens from spec §1 (light) and iteration 5 (dark).
///
/// The active palette is a process-wide setting switched by the app root
/// (see `MarkdownNotesApp`), which then rebuilds the whole element tree.
abstract final class AppColors {
  static bool dark = false;

  static Color _p(int light, int darkValue) => Color(dark ? darkValue : light);

  static Color get bg => _p(0xFFF5F5F7, 0xFF000000);
  static Color get surface => _p(0xFFFFFFFF, 0xFF1C1C1E);
  static Color get text => _p(0xFF1C1C1E, 0xFFF5F5F7);
  static Color get textSecondary => _p(0xFF6E6E73, 0xFFA1A1A6);
  static Color get textTertiary => _p(0xFF8E8E93, 0xFF8E8E93);
  static Color get fill => _p(0xFFE9E9EE, 0xFF2C2C2E);
  static Color get separator => _p(0xFFE5E5EA, 0xFF38383A);
  static Color get accent => _p(0xFF5B4FE9, 0xFF7D74FF);
  static Color get accentSoft => _p(0xFFECEBFF, 0xFF2A2650);
  static Color get star => _p(0xFFF5A623, 0xFFFFB340);
  static Color get danger => _p(0xFFE5484D, 0xFFFF6369);
  static Color get codeBg => _p(0xFF1C1C1E, 0xFF2C2C2E);
  static Color get codeText => _p(0xFFF5F5F7, 0xFFF5F5F7);
  static Color get toastBg => _p(0xFF1C1C1E, 0xFF3A3A3C);

  /// Always white (text on accent, switch knob, toast text).
  static const white = Color(0xFFFFFFFF);
}

abstract final class Insets {
  static const safeTop = 62.0;
  static const safeBottom = 34.0;
}

const _systemText = 'CupertinoSystemText';
const monoFamily = 'Menlo';

/// Flutter applies Apple's optical-size tracking to the system font unless an
/// explicit letter spacing is given. The reference renders use untracked
/// SF Pro Text, so pass a (visually zero) explicit spacing to opt out.
double _tracking(double size) => 0.001;

/// System font (SF Pro) text style. [lineHeight] is in points.
TextStyle sf(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? lineHeight,
  FontStyle? style,
}) => TextStyle(
  fontFamily: _systemText,
  fontSize: size,
  letterSpacing: _tracking(size),
  fontWeight: weight,
  fontStyle: style,
  color: color ?? AppColors.text,
  height: lineHeight == null ? null : lineHeight / size,
  leadingDistribution: TextLeadingDistribution.even,
  decoration: TextDecoration.none,
);

/// Menlo monospace text style. [lineHeight] is in points.
TextStyle mono(double size, {Color? color, double? lineHeight}) => TextStyle(
  fontFamily: monoFamily,
  // Menlo only exists on Apple platforms; Android resolves the generic
  // `monospace` family (Droid Sans Mono / Cutive Mono) instead.
  fontFamilyFallback: const ['monospace'],
  fontSize: size,
  color: color ?? AppColors.text,
  height: lineHeight == null ? null : lineHeight / size,
  leadingDistribution: TextLeadingDistribution.even,
  decoration: TextDecoration.none,
);
