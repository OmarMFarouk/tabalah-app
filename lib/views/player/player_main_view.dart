import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/player/attendance_view.dart';
import 'package:tabala/views/player/payments_view.dart';
import 'package:tabala/views/player/player_home_view.dart';
import 'package:tabala/views/player/profile_view.dart';
import 'package:tabala/views/player/sports_view.dart';

/// The player's shell. Five tabs: the wallet tab is new, and exists because
/// `/player/payments` and `/player/enrollments` were live on the backend with
/// nowhere in the app to surface them.
class PlayerMainView extends StatefulWidget {
  PlayerMainView({super.key});

  @override
  State<PlayerMainView> createState() => _PlayerMainViewState();
}

class _PlayerMainViewState extends State<PlayerMainView> {
  int _index = 0;

  /// Built fresh on every build rather than held in a `static const` list.
  ///
  /// A const list holds canonicalised widget instances, so IndexedStack
  /// would hand Flutter the same identical instances on every rebuild and
  /// every one of those subtrees would be skipped. Since the colours here
  /// come from static getters evaluated at build time, a skipped subtree
  /// keeps painting the previous theme - which is why a theme toggle used to
  /// leave half the screen behind.
  ///
  /// New instances of the same type with the same key still satisfy
  /// `Widget.canUpdate`, so each screen's State (and its cubits) survives.
  List<Widget> get _screens => [
        PlayerHomeView(),
        SportsView(),
        AttendanceView(),
        PaymentsView(),
        ProfileView(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: ClubBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        items: [
          ClubNavItem(Icons.home_rounded, Icons.home_outlined, 'home'.tr()),
          ClubNavItem(Icons.sports_soccer_rounded, Icons.sports_soccer_outlined,
              'sports'.tr()),
          ClubNavItem(Icons.fact_check_rounded, Icons.fact_check_outlined,
              'attendance'.tr()),
          ClubNavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined,
              'wallet'.tr()),
          ClubNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'profile'.tr()),
        ],
      ),
    );
  }
}

class ClubNavItem {
  final IconData active;
  final IconData inactive;
  final String label;

  const ClubNavItem(this.active, this.inactive, this.label);
}

/// A floating pill nav bar with a gold capsule that slides between tabs.
///
/// The capsule is one positioned widget animated across the bar rather than a
/// background per item, so the gold reads as a single object moving instead
/// of five backgrounds blinking. The icon lift, the swap fade and the little
/// elastic pop all hang off the same selection change, which keeps them
/// reading as one gesture.
///
/// Colour note, and this is the bug from the screenshots: the capsule is gold
/// in **both** themes, so anything drawn on top of it must use a pinned dark
/// ink rather than the theme's ink. The theme ink is near-white in dark mode,
/// which is what made the active label vanish.
class ClubBottomNav extends StatefulWidget {
  /// How much vertical space the pill actually occupies: 56 for the row,
  /// 6 of inner padding either side, and a 12 bottom margin.
  ///
  /// Screens under `extendBody: true` scroll *behind* this bar, so they have
  /// to reserve the space themselves. Hardcoding a guess is what left the
  /// quick-action buttons touching the nav bar - the guess came out about
  /// equal to the pill alone and left nothing for the gesture inset
  /// underneath it, let alone a gap. [scrollPadding] does the arithmetic.
  static const double barHeight = 56 + 12 + 12;

  /// Bottom padding a scrolling screen needs so its last row clears the nav
  /// bar with room to breathe, including the device's own bottom inset.
  static double scrollPadding(BuildContext context, {double extra = 28}) =>
      barHeight + MediaQuery.paddingOf(context).bottom + extra;

  final int index;
  final ValueChanged<int> onChanged;
  final List<ClubNavItem> items;

  const ClubBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  State<ClubBottomNav> createState() => _ClubBottomNavState();
}

class _ClubBottomNavState extends State<ClubBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant ClubBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Replay the pop only when the tab actually changed - this widget also
    // rebuilds on a theme switch, and re-firing then would look like a twitch.
    if (oldWidget.index != widget.index) {
      _bounce
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.navSurface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.navBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .45 : .10),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / widget.items.length;

            return SizedBox(
              height: 56,
              child: Stack(
                children: [
                  // AnimatedPositionedDirectional keeps the capsule on the
                  // correct side under RTL with no manual index flipping.
                  AnimatedPositionedDirectional(
                    duration: const Duration(milliseconds: 340),
                    curve: Curves.easeOutBack,
                    start: slotWidth * widget.index,
                    top: 0,
                    bottom: 0,
                    width: slotWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          // Deep club green in both themes, so the gold ink
                          // on top keeps the same contrast either way.
                          gradient: const LinearGradient(
                            // Top stop measured against the gold ink: #1F5C41
                            // came out at 3.75:1, under AA. #16412E clears
                            // 5.46:1 and the gradient still reads.
                            colors: [Color(0xFF16412E), Color(0xFF0A2016)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: .28),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      widget.items.length,
                      (i) => Expanded(
                        child: _NavSlot(
                          item: widget.items[i],
                          selected: i == widget.index,
                          bounce: _bounce,
                          onTap: () => widget.onChanged(i),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  final ClubNavItem item;
  final bool selected;
  final Animation<double> bounce;
  final VoidCallback onTap;

  const _NavSlot({
    required this.item,
    required this.selected,
    required this.bounce,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Requested: the selected item is drawn in the gold accent.
    //
    // That changes what the capsule behind it has to be. Gold ink on a gold
    // capsule is a 1:1 contrast ratio - literally invisible - so the capsule
    // is now the deep club green, which puts this at 7.0:1 and reads as the
    // club's own colours rather than a highlighter.
    final onGold = AppColors.accentcolor;
    final idle = AppColors.navIdle;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedBuilder(
        animation: bounce,
        builder: (context, _) {
          // A short overshoot-and-settle on the freshly selected icon.
          final pop = selected
              ? 1 + (Curves.elasticOut.transform(bounce.value.clamp(0.0, 1.0)) - 1) * .20
              : 1.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                offset: Offset(0, selected ? -0.05 : 0),
                child: Transform.scale(
                  scale: pop,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Icon(
                      selected ? item.active : item.inactive,
                      key: ValueKey(selected),
                      size: selected ? 23 : 21,
                      color: selected ? onGold : idle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                style: selected
                    ? AppStyles.bold12Black.copyWith(fontSize: 10.5, color: onGold)
                    : AppStyles.regular12Grey.copyWith(fontSize: 10.5, color: idle),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
