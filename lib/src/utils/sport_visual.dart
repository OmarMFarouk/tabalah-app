import 'package:flutter/material.dart';

/// The key → glyph map for the icon a sport is tagged with.
///
/// The API only ever ships the key (see `App\Support\SportIcons`), never a
/// font codepoint: this app and the admin panel draw at different sizes on
/// different platforms, so each owns its own glyph for the same sport. Keys
/// this build doesn't recognise fall back to a neutral icon rather than a
/// blank box, which is what lets the backend add a sport without waiting on
/// an app release.
class SportVisual {
  const SportVisual._();

  static const IconData fallback = Icons.sports_rounded;

  static const Map<String, IconData> _glyphs = {
    'soccer': Icons.sports_soccer_rounded,
    'basketball': Icons.sports_basketball_rounded,
    'volleyball': Icons.sports_volleyball_rounded,
    'tennis': Icons.sports_tennis_rounded,
    'table_tennis': Icons.sports_tennis_outlined,
    'badminton': Icons.sports_tennis_rounded,
    'handball': Icons.sports_handball_rounded,
    'baseball': Icons.sports_baseball_rounded,
    'cricket': Icons.sports_cricket_rounded,
    'rugby': Icons.sports_rugby_rounded,
    'hockey': Icons.sports_hockey_rounded,
    'golf': Icons.sports_golf_rounded,
    'swimming': Icons.pool_rounded,
    'surfing': Icons.surfing_rounded,
    'sailing': Icons.sailing_rounded,
    'running': Icons.directions_run_rounded,
    'athletics': Icons.sports_score_rounded,
    'cycling': Icons.directions_bike_rounded,
    'gym': Icons.fitness_center_rounded,
    'boxing': Icons.sports_mma_rounded,
    'martial_arts': Icons.sports_kabaddi_rounded,
    'wrestling': Icons.sports_kabaddi_outlined,
    'fencing': Icons.sports_martial_arts_rounded,
    'archery': Icons.my_location_rounded,
    'shooting': Icons.gps_fixed_rounded,
    'gymnastics': Icons.accessibility_new_rounded,
    'yoga': Icons.self_improvement_rounded,
    'dance': Icons.music_note_rounded,
    'skating': Icons.ice_skating_rounded,
    'skiing': Icons.downhill_skiing_rounded,
    'snowboarding': Icons.snowboarding_rounded,
    'climbing': Icons.terrain_rounded,
    'hiking': Icons.hiking_rounded,
    'equestrian': Icons.bedroom_baby_rounded,
    'esports': Icons.sports_esports_rounded,
    'chess': Icons.grid_on_rounded,
    'darts': Icons.adjust_rounded,
    'bowling': Icons.sports_rounded,
    'billiards': Icons.circle_rounded,
    'kayaking': Icons.kayaking_rounded,
  };

  static IconData icon(String? key) =>
      key == null ? fallback : (_glyphs[key] ?? fallback);

  /// Whether a URL is something the app can actually load. Uploaded artwork
  /// comes back as an absolute URL from the API; anything else (a bare disk
  /// path from an older payload) is not loadable here.
  static bool usable(String? url) =>
      url != null && url.isNotEmpty && url.startsWith('http');
}
