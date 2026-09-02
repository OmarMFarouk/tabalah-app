import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/status_ui.dart';
import 'package:tabala/src/utils/sport_visual.dart';

/// The shared visual language for the club app.
///
/// Everything here reads its colours from AppColors' theme-aware getters
/// rather than hardcoding `Colors.white`, which is what lets the same widget
/// tree render correctly in both the light (parchment + pitch green) and
/// dark (night green + gold) themes.

// ─────────────────────────────────────────────────────────────────────────
//  Surfaces
// ─────────────────────────────────────────────────────────────────────────

/// The standard raised surface: rounded, hairline-bordered, no drop shadow
/// in dark mode (shadows are invisible against a near-black background and
/// only muddy the edges).
class ClubCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final Border? border;

  /// Optional artwork painted behind the card's surface at [imageOpacity].
  ///
  /// The surface colour stays on top at near-full alpha, so a bright or
  /// busy photo cannot drop the contrast under the card's text. A null,
  /// broken or still-loading image leaves the card exactly as it was.
  final String? imageUrl;

  /// Low on purpose - this is a wash, not a hero image. Applied once, over
  /// an opaque surface, so the number means what it says.
  final double imageOpacity;

  const ClubCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = 20,
    this.color,
    this.border,
    this.imageUrl,
    this.imageOpacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surface = color ?? AppColors.surfacecolor;
    final hasArt = SportVisual.usable(imageUrl);

    final card = Container(
      decoration: BoxDecoration(
        // Transparent when there is art, because the wash below has to show
        // through the surface rather than sit behind an opaque fill.
        color: hasArt ? Colors.transparent : surface,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: AppColors.borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      clipBehavior: hasArt ? Clip.antiAlias : Clip.none,
      child: hasArt
          ? Stack(
              children: [
                // Surface first, fully opaque, then the artwork washed over
                // it. The order matters and used to be the other way round:
                // the image was drawn at `imageOpacity` and *then* covered
                // by the surface at 88% alpha, which multiplied out to
                // roughly 1.7% — a picture that was technically painted and
                // in practice invisible, so a card with artwork looked
                // identical to one without. Painting it once, on top,
                // makes `imageOpacity` mean what it claims.
                Positioned.fill(child: ColoredBox(color: surface)),
                Positioned.fill(
                  child: Opacity(
                    opacity: imageOpacity,
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      // A broken or still-loading image leaves the plain
                      // surface showing, never a gap.
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      loadingBuilder: (_, image, progress) => progress == null
                          ? image
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                Padding(padding: padding, child: child),
              ],
            )
          : Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return margin == null ? card : Padding(padding: margin!, child: card);
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: card,
        ),
      ),
    );
  }
}

/// A dark green / gold gradient panel used for hero headers and featured
/// cards.
///
/// The green gradient is deliberately **not** theme-dependent. Everything
/// drawn on this panel - titles, StatTile values, the attendance ring - uses
/// white, so the panel has to stay dark in light mode too. Routing it
/// through a theme-aware getter only creates a way for it to come out light
/// and take the white text with it.
class ClubGradientPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool gold;

  /// Optional artwork painted *behind* the gradient, at [imageOpacity].
  ///
  /// The gradient stays on top rather than being replaced, which is what
  /// keeps the panel readable whatever picture the club uploaded: a busy or
  /// bright photo can never push the contrast under the text, because the
  /// text is still sitting on the same gradient it always was. A missing or
  /// broken image degrades to exactly the panel as it was before.
  final String? imageUrl;

  /// Low by design. Anything much higher starts competing with the figures
  /// drawn on top; this is a backdrop, not a hero image.
  final double imageOpacity;

  const ClubGradientPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.gold = false,
    this.imageUrl,
    this.imageOpacity = 0.16,
  });

  @override
  Widget build(BuildContext context) {
    // This panel is now LIGHT in light mode and dark in dark mode, and its
    // content uses the theme's own ink.
    //
    // The previous design made it a fixed-dark surface with hardcoded white
    // text. That is a bet: it only works while the fill definitely paints
    // dark. When anything at all goes wrong with that fill - and it did -
    // white text lands on a light background and the screen is unreadable.
    // Worse, it fails silently, because nothing in the widget tree knows the
    // text and the background disagree.
    //
    // Deriving both from `Theme.of(context)` removes the bet. The ink and
    // the surface now come from the same source, in the same build, through
    // an InheritedWidget that cannot be stale - so they cannot disagree,
    // whatever else is wrong.
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = LinearGradient(
      colors: gold
          ? AppColors.primaryGradient
          : (isDark
                ? const [Color(0xFF174B34), Color(0xFF0C2418)]
                : const [Color(0xFFF1F6F2), Color(0xFFE2ECE5)]),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final hasArt = imageUrl != null && imageUrl!.startsWith('http');

    return DefaultTextStyle.merge(
      // A floor for any text that forgets to set a colour: it lands on the
      // theme's onSurface, never on a fixed white.
      style: TextStyle(color: scheme.onSurface),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: gold
                ? Colors.transparent
                : (isDark ? const Color(0x59D4AF37) : const Color(0x3DA8841B)),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (hasArt)
              Positioned.fill(
                child: Opacity(
                  opacity: imageOpacity,
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    // A backdrop must never announce itself while loading or
                    // failing - both fall through to the bare gradient.
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const SizedBox.shrink(),
                  ),
                ),
              ),
            // The gradient sits above the art, so contrast for the content
            // is fixed regardless of the picture.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasArt
                        ? gradient.colors
                              .map((c) => c.withValues(alpha: 0.86))
                              .toList()
                        : gradient.colors,
                    begin: gradient.begin,
                    end: gradient.end,
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Ink and fills for content sitting on [ClubGradientPanel].
///
/// Everything here comes from `Theme.of(context)`, which is an
/// InheritedWidget - a widget that reads it registers a dependency and is
/// rebuilt when it changes, so these values are structurally incapable of
/// being stale. That is the difference from the static getters, and the
/// reason panel content routes through here specifically.
class PanelInk {
  PanelInk._();

  /// Headlines and figures.
  static Color strong(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Captions and secondary labels.
  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: .68);

  /// Tile backgrounds inside the panel.
  static Color fill(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: .06);

  /// Hairlines, dividers and progress tracks inside the panel.
  static Color line(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: .14);
}

// ─────────────────────────────────────────────────────────────────────────
//  Headings
// ─────────────────────────────────────────────────────────────────────────

/// A section title with an optional "see all" affordance. The little gold
/// rule to the left of the title is the club's signature - it is what makes
/// a list read as part of a club app rather than a generic admin list.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(0, 20, 0, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: subtitle == null ? 18 : 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.bold16Black),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppStyles.regular12Grey),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!, style: AppStyles.medium12Grey),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Chips & badges
// ─────────────────────────────────────────────────────────────────────────

/// A tinted status pill. [color] is the semantic colour from StatusUi; the
/// fill is a low-alpha wash of it so the pill stays legible in both themes
/// without needing a separate light/dark colour per status.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool solid;

  /// Tighter padding and smaller ink, for chips sitting inside a card's
  /// content rather than standing alone in a row.
  final bool dense;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.solid = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    // The fill keeps the raw status colour; the foreground is clamped so it
    // stays legible against that fill. Writing the raw colour on a 14%-alpha
    // wash of itself is what made the gold and green chips unreadable.
    final ink = StatusUi.readable(context, color);

    // A solid chip is a dark-enough fill in both themes, so white is safe on
    // it - but only because `readable` is not applied to the fill.
    final onSolid = Colors.white;

    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solid ? ink : color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: solid ? 0 : .40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: solid ? onSolid : ink),
            SizedBox(width: dense ? 4 : 5),
          ],
          Text(
            label,
            style: AppStyles.medium12Black.copyWith(
              color: solid ? onSolid : ink,
              fontSize: dense ? 10.5 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar with a graceful fallback to the person's initial. The API sends
/// `avatar_url` as a ready-to-render absolute URL, but it is null for
/// members who never set one, and the raw `avatar` column may hold a
/// storage-relative path that the app cannot load - so the initial is the
/// common case, not the edge case.
class ClubAvatar extends StatelessWidget {
  final String initial;
  final String? photoUrl;
  final double size;
  final bool ring;

  /// Set on the profile screens, where the picture is also the control for
  /// changing it. Null everywhere else — in a list or a session card the
  /// avatar is just an identifier, and making it tappable there would
  /// promise something that isn't there.
  final VoidCallback? onTap;

  const ClubAvatar({
    super.key,
    required this.initial,
    this.photoUrl,
    this.size = 44,
    this.ring = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inner = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Constant dark green: unlike the panel, this circle is small and
        // always brand-coloured in both themes, so a fixed white initial on
        // top of it is safe.
        gradient: photoUrl == null
            ? const LinearGradient(
                colors: [Color(0xFF1F5C41), Color(0xFF0E2E1F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: photoUrl != null
            ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: photoUrl == null
          ? Text(
              initial,
              style: (isDark ? AppStyles.bold16White : AppStyles.bold16Black)
                  .copyWith(fontSize: size * .38),
            )
          : null,
    );

    final framed = !ring
        ? inner
        : Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .55),
                width: 1.5,
              ),
            ),
            child: inner,
          );

    if (onTap == null) return framed;

    // A camera badge on the rim, because a circle that happens to be
    // tappable looks exactly like one that isn't.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          framed,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: AppColors.surfacecolor, width: 2),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                size: size * .20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Stats
// ─────────────────────────────────────────────────────────────────────────

/// A compact metric block. Used in rows of two or three inside cards.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accent;
  final bool onDark;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? AppColors.goldInk;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        // `onDark` is a legacy name - it means "I am sitting on the club
        // panel". The panel now follows the theme, so these do too.
        color: onDark ? PanelInk.fill(context) : AppColors.cardcolor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onDark ? PanelInk.line(context) : AppColors.borderColor,
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: tone),
            const SizedBox(height: 6),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: onDark
                ? AppStyles.bold16Black.copyWith(
                    color: PanelInk.strong(context),
                  )
                : AppStyles.bold16Black,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: onDark
                ? AppStyles.regular12Grey.copyWith(
                    color: PanelInk.muted(context),
                  )
                : AppStyles.regular12Grey,
          ),
        ],
      ),
    );
  }
}

/// A slim labelled progress bar, used for attendance rates and KPI targets.
class ProgressRow extends StatelessWidget {
  final String label;
  final String trailing;

  /// 0..1, already clamped by the caller.
  final double value;
  final Color? color;
  final bool onDark;

  const ProgressRow({
    super.key,
    required this.label,
    required this.trailing,
    required this.value,
    this.color,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.goldInk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: onDark
                    ? AppStyles.medium14Black.copyWith(
                        color: PanelInk.strong(context),
                      )
                    : AppStyles.medium14Black,
              ),
            ),
            Text(
              trailing,
              style: onDark
                  ? AppStyles.bold14Black.copyWith(
                      color: PanelInk.strong(context),
                    )
                  : AppStyles.bold14Black,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: onDark
                ? PanelInk.line(context)
                : AppColors.borderColor,
            valueColor: AlwaysStoppedAnimation(tone),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Empty / error states
// ─────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .3),
              ),
            ),
            child: Icon(icon, size: 28, color: AppColors.goldInk),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppStyles.bold16Black,
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppStyles.regular14Grey,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Loading / error / empty, in one place, so each screen's build method
/// stays focused on its actual content.
class AsyncStateView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String? emptyMessage;
  final VoidCallback? onRetry;
  final Widget child;

  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.child,
    this.errorMessage,
    this.isEmpty = false,
    this.emptyMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(
            color: AppColors.goldInk,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: EmptyState(
          icon: Icons.wifi_tethering_error_rounded,
          title: 'something_went_wrong'.tr(),
          message: errorMessage,
          actionLabel: onRetry == null ? null : 'retry'.tr(),
          onAction: onRetry,
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.inbox_rounded,
          title: emptyMessage ?? 'no_data'.tr(),
        ),
      );
    }

    return child;
  }
}

/// A sport's mark: its uploaded photo when the club set one, its picked
/// glyph otherwise, and a neutral glyph when it has neither.
///
/// The precedence is fixed here rather than at each call site because it is
/// a promise the admin panel makes when it offers both fields - "upload an
/// image and it replaces the icon". Every screen that draws a sport has to
/// agree on that, or the panel's preview stops predicting the app.
class SportMark extends StatelessWidget {
  final String? imageUrl;
  final String? icon;
  final double size;
  final double radius;

  /// Draws on the club gradient rather than on a plain surface.
  final bool onPanel;

  const SportMark({
    super.key,
    this.imageUrl,
    this.icon,
    this.size = 44,
    this.radius = 14,
    this.onPanel = false,
  });

  @override
  Widget build(BuildContext context) {
    final showImage = SportVisual.usable(imageUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: onPanel ? .18 : .12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: onPanel
              ? PanelInk.line(context)
              : AppColors.primary.withValues(alpha: .22),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: showImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              // A broken or slow image must not leave a hole where the
              // sport's mark should be - both states fall back to the glyph.
              errorBuilder: (_, _, _) => _glyph(),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _glyph(),
            )
          : _glyph(),
    );
  }

  Widget _glyph() => Center(
        child: Icon(
          SportVisual.icon(icon),
          size: size * .52,
          color: AppColors.goldInk,
        ),
      );
}
