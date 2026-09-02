import 'package:flutter/material.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/constants/app_assets.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// The club crest.
///
/// The artwork is gold on transparent, so it reads correctly on the light
/// parchment *and* on the dark green — no per-theme variant needed. What it
/// does need is something behind it with enough contrast, which is why the
/// [boxed] form sits it on a fixed deep-green tile rather than on whatever
/// surface happens to be underneath.
///
/// Falls back to a gold "T" if the asset is missing, so a forgotten pubspec
/// entry shows a wordmark instead of a grey broken-image box.
class ClubLogo extends StatelessWidget {
  final double size;

  /// Wraps the mark in a rounded deep-green tile. Use on light backgrounds
  /// and anywhere the logo needs to read as an app icon.
  final bool boxed;

  const ClubLogo({super.key, this.size = 48, this.boxed = false});

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Center(
        child: Text(
          'T',
          style: AppStyles.bold32Gold.copyWith(
          fontSize: size * .62,
          // The boxed form sits on deep green, where the light-mode deep
          // gold would go muddy - use the bright brand value there.
          color: boxed ? AppColors.primary : AppColors.goldInk,
        ),
        ),
      ),
    );

    if (!boxed) return SizedBox(width: size, height: size, child: mark);

    final box = size * 1.42;

    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.clubGreenDeep,
        borderRadius: BorderRadius.circular(box * .28),
        border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
      ),
      child: mark,
    );
  }
}

/// A drop-in replacement for the `Padding` that wraps a full-screen form.
///
/// Same two parameters as `Padding`, so swapping it in changes nothing about
/// the tree below it — but it fixes the overflow the auth screens hit when
/// the keyboard opens.
///
/// The cause: those screens are a `Column` with a `Spacer()` pushing the
/// submit button to the bottom. When the keyboard appears the Scaffold
/// shrinks the body, the Column's children no longer fit, and `Spacer` can't
/// take negative space — so it overflows instead of yielding.
///
/// The fix is the standard scroll-with-minimum-height sandwich:
/// `SingleChildScrollView` makes the content scrollable, `ConstrainedBox`
/// keeps it at least as tall as the viewport so the layout is unchanged when
/// there's room, and `IntrinsicHeight` gives the `Spacer` a finite height to
/// divide up. Extra bottom padding equal to the keyboard inset keeps the
/// focused field clear of the keys.
class KeyboardAwareBody extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const KeyboardAwareBody({
    super.key,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final resolved = padding.resolve(Directionality.of(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        // The minimum height the content should keep. Subtracting the
        // vertical padding stops the ConstrainedBox from forcing a scroll
        // that isn't needed.
        final minHeight = constraints.maxHeight - resolved.vertical;

        return SingleChildScrollView(
          padding: resolved.copyWith(bottom: resolved.bottom + keyboard),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight < 0 ? 0 : minHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}
