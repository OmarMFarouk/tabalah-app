/// Process-wide facts the API layer needs but has no context to look up.
///
/// Two things live here, and both are read on every request:
///
/// * **The language.** Catalogue text an admin typed - sport names,
///   membership names, payment methods - is stored per language on the
///   server, so the *server* has to know which one to answer in. Sending it
///   as a header rather than resolving on the client is what stops the app
///   needing a translation table for content it did not write.
///
/// * **Whether this session is a guardian.** A parent signs in with a code
///   and gets a read-only token that reaches `/guardian/*` instead of
///   `/player/*`. Holding that as a scope flag means the player cubits,
///   models and screens work unchanged for both - see [ApiEndpoints], which
///   swaps the prefix off this value.
///
/// Deliberately plain statics rather than a provider: the API client is a
/// singleton constructed before any widget exists, and threading a
/// BuildContext into an interceptor is not possible.
class AppScope {
  AppScope._();

  /// The language the API should answer in - `ar` or `en`.
  ///
  /// Kept in step with EasyLocalization from the app root. The backend
  /// falls back to Arabic for anything it doesn't recognise, so a stale or
  /// odd value degrades to readable text rather than to blanks.
  static String locale = 'en';

  /// True while a parent is signed in with a player's code.
  ///
  /// Set at login and restored on bootstrap from the stored session, so it
  /// is already correct before the first request goes out.
  static bool isGuardian = false;

  /// The player a guardian is watching. Null for a normal session.
  static String? watchingPlayerName;

  static void clearGuardian() {
    isGuardian = false;
    watchingPlayerName = null;
  }
}
