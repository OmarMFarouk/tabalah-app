import 'package:flutter/material.dart';

import 'package:tabala/src/theme/theme_signal.dart';

// ─────────────────────────────────────────────
//  STATIC PALETTE
//  الألوان الثابتة
// ─────────────────────────────────────────────
class AppColors {
  // Backgrounds
  static const backGround = Color(0xFF08140D);
  static const secondary = Color(0xFF0F2217);

  static const primary = Color(0xFFD4AF37); // Classic Gold
  static const primaryGradient = [
    Color(0xFFF3D573), // Bright Gold
    Color(0xFFD4AF37), // Core Gold
    Color(0xFFA8841B), // Deep Gold
  ];

  static const secondaryGradient = [Color(0xFF142B1C), Color(0xFF1C3A27)];

  // Accent Colors
  static const primaryFont = Colors.white;
  static const grey = Colors.grey;
  static const red = Color(0xFFFF5C6A);
  static const yellow = Color(0xFFFFC847);
  static const purple = Color(0xFFA78BFA);
  static const green = Color(0xFF2EAD68); // Academy Green
  static const blue = Color(0xFF4FA3E0);
  static const orange = Color(0xFFFF8A65);

  // Base
  static const Color scaffold = Color(0xFF06100A);
  static const Color surface = Color(0xFF0D1E14);
  static const Color card = Color(0xFF12271A);

  // Borders & dividers
  static const Color border = Color(0x14FFFFFF);
  static const Color divider = Color(0x0DFFFFFF);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8FA897);
  static const Color textMuted = Color(0xFF4C6353);

  static const Color white5 = Color(0x0DFFFFFF);
  static const Color white8 = Color(0x14FFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);

  // ───────────────────────────────────────────
  //  CLUB GREENS (light-mode counterparts)
  // ───────────────────────────────────────────

  /// The deep pitch green used for primary surfaces/buttons in light mode.
  /// Dark enough that white text always clears contrast on top of it.
  static const Color clubGreen = Color(0xFF154530);
  static const Color clubGreenDeep = Color(0xFF0E2E1F);
  static const Color clubGreenSoft = Color(0xFF1F5C41);

  static const Color goldDeep = Color(0xFFA8841B);
  static const Color goldSoft = Color(0xFFE8C860);

  // ───────────────────────────────────────────
  //  BACK-COMPAT ALIASES
  //
  //  The screens written before this palette landed reference these names
  //  directly. They stay, but the ones that describe a *surface* (rather
  //  than a fixed ink colour) became getters so the whole existing UI
  //  follows the light/dark switch without touching every call site.
  //  See ThemeSignal for why a getter can answer this without a context.
  // ───────────────────────────────────────────

  /// Brand colour for filled buttons and progress arcs. Green in both
  /// themes, because every call site pairs it with **white** text.
  ///
  /// This used to fall back to deep gold in dark mode, which is where the
  /// unreadable buttons came from: white on #A8841B is roughly 2.5:1, well
  /// under the 4.5:1 a label needs. The dark variant is now a lifted green
  /// that clears the bar against white while still reading as brand.
  /// Gold lives on as [primary] / [accentcolor] for accents, capsules and
  /// rings - surfaces whose foreground is pinned dark, never white.
  static Color get primarycolor => ThemeSignal.pick(clubGreen, clubGreenSoft);

  /// Gold as **text**, as opposed to gold as a fill.
  ///
  /// The brand gold (#D4AF37) measures 2.10:1 on white - effectively
  /// invisible, and the cause of the faint gold labels in light mode. Gold
  /// is a light colour, so it can only be text on a dark background. Light
  /// mode therefore uses a deep antique gold that still reads as gold but
  /// clears 6:1 on a white card; dark mode keeps the brand value, which
  /// measures 8.23:1 on the dark surface.
  ///
  /// Use [primary] instead only where the gold is a *fill* with dark ink on
  /// top - the nav capsule, the gold button, the FAB. Anywhere gold is the
  /// foreground (icon, spinner, border, label) it must be this.
  static Color get goldInk => ThemeSignal.pick(const Color(0xFF7A5F0F), primary);

  /// Brand colour for *text and icons drawn directly on the page*, as
  /// opposed to on a filled brand surface. Green reads well on the light
  /// parchment; on the near-black dark background green disappears, so dark
  /// mode uses gold instead. This is the pairing the AppStyles `*Primary`
  /// styles use.
  static Color get brandInk => ThemeSignal.pick(clubGreen, primary);

  /// The gold accent. Use this for highlights, medals, ratings, dividers -
  /// anything that should read "club", not "action".
  static Color get accentcolor => primary;

  static const Color whitecolor = Color(0xFFFFFFFF);
  static const Color blackcolor = Colors.black;

  static Color get yellowcolor => ThemeSignal.pick(const Color(0xFFC79A17), yellow);
  static Color get darkyellowcolor => goldDeep;
  static Color get redcolor => ThemeSignal.pick(const Color(0xFFC0392B), red);
  static Color get greencolor => ThemeSignal.pick(const Color(0xFF1E8A50), green);
  static Color get bluecolor => ThemeSignal.pick(const Color(0xFF2E7FB8), blue);
  static Color get lightbluecolor => bluecolor;
  static Color get purplecolor => ThemeSignal.pick(const Color(0xFF7C5BD9), purple);
  static Color get orangecolor => ThemeSignal.pick(const Color(0xFFD9663F), orange);

  static Color get greycolor => ThemeSignal.pick(const Color(0xFF6B7B70), textSecondary);

  /// Page background.
  static Color get scaffoldcolor => ThemeSignal.pick(const Color(0xFFF4F6F4), backGround);

  /// Raised surface (cards, sheets, tiles) - the light-mode replacement for
  /// every hardcoded `Colors.white` card in the app.
  static Color get surfacecolor => ThemeSignal.pick(const Color(0xFFFFFFFF), surface);

  /// A slightly recessed surface for nested tiles inside a card.
  static Color get cardcolor => ThemeSignal.pick(const Color(0xFFEDF1EE), card);

  /// The old parchment tone, now a soft green-gold wash in light mode and a
  /// lifted card in dark mode.
  static Color get creamColor => ThemeSignal.pick(const Color(0xFFF6EFDC), const Color(0xFF16301F));

  static Color get borderColor => ThemeSignal.pick(const Color(0xFFDCE4DD), const Color(0xFF1F402B));

  static Color get lightGreen => ThemeSignal.pick(const Color(0xFFE3F3E8), const Color(0xFF12351F));
  static Color get lightOrange => ThemeSignal.pick(const Color(0xFFFCEDD8), const Color(0xFF3A2A14));
  static Color get lightRed => ThemeSignal.pick(const Color(0xFFFBE4E5), const Color(0xFF3A1A1D));
  static Color get lightBlue => ThemeSignal.pick(const Color(0xFFE2EFF9), const Color(0xFF12283A));

  /// Ink colours. `textcolor` is the one that flips; the Black/White named
  /// styles in AppStyles route through these.
  static Color get textcolor => ThemeSignal.pick(const Color(0xFF0A180F), const Color(0xFFF1F5F2));
  static Color get subtextcolor => ThemeSignal.pick(const Color(0xFF4A6150), const Color(0xFF8BA292));

  /// The club gradient for hero panels. Fixed in both themes on purpose:
  /// everything drawn on it is white, so it must never lighten.
  static const List<Color> clubGradient = [Color(0xFF174B34), Color(0xFF0C2418)];

  /// Kept as an alias for any call site still asking for the old name.
  static List<Color> get heroGradient => clubGradient;

  static List<Color> get goldGradient => primaryGradient;

  // ── Bottom navigation ──────────────────────────────────────────────
  //
  // Broken out because the nav bar is the one surface where the active
  // state sits on gold in *both* themes, so its foreground cannot be
  // derived from the theme's ink - a near-white ink on gold is the
  // invisible active label from the bug report. `onGold` is pinned dark.

  static Color get navSurface =>
      ThemeSignal.pick(const Color(0xFFFFFFFF), const Color(0xFF102418));

  static Color get navBorder =>
      ThemeSignal.pick(const Color(0xFFE2E8E3), const Color(0xFF244A32));

  /// Unselected nav icon/label. Needs to clear contrast against
  /// [navSurface] in both themes, which is why it is not just `greycolor`.
  static Color get navIdle =>
      ThemeSignal.pick(const Color(0xFF5C7166), const Color(0xFF93AC9B));

  /// Anything drawn on top of the gold capsule.
  static Color get onGold => clubGreenDeep;
}

// ─────────────────────────────────────────────
//  GLOBAL COLORS — ألوان التطبيق
//  Usage: GlobalColors.bg(context) / GlobalColors.accent
// ─────────────────────────────────────────────
class GlobalColors {
  GlobalColors._();

  // Read the brightness off the theme, not off a cubit.
  //
  // These helpers get called from event handlers and from dialog
  // builders holding a caller's context, and `context.watch` is only
  // legal while that exact context is building — anywhere else it
  // throws. The app root already feeds `isDark` into the MaterialApp
  // theme, so the theme carries the same answer and is safe to read from
  // anywhere, while still rebuilding when the toggle flips.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── Backgrounds ──────────────────────────────
  static Color bg(BuildContext context) =>
      isDark(context) ? const Color(0xFF08140D) : const Color(0xFFF3F5F3);

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF0E2217) : const Color(0xFFFFFFFF);

  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF152D1F) : const Color(0xFFE5EBE6);

  // ── Borders ──────────────────────────────────
  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F402B) : const Color(0xFFCBD6CD);

  // ── Brand / Accent ───────────────────────────
  static Color get accent => const Color(0xFFD4AF37); // Brand Metallic Gold
  static Color get accentSoft => const Color(0xFFE8C860); // Soft Light Gold

  // ── Semantic ─────────────────────────────────
  static Color get green => const Color(0xFF2EAD68);
  static Color get red => const Color(0xFFFF5C6A);
  static Color get gold => const Color(0xFFD4AF37);
  static Color get blue => const Color(0xFF4FA3E0);
  static Color get purple => const Color(0xFFA78BFA);

  // ── Text ─────────────────────────────────────
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF1F5F2) : const Color(0xFF0A180F);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF8BA292) : const Color(0xFF4A6150);
}
