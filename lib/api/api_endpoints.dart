import 'package:tabala/src/app_scope.dart';

/// Every path the app calls, in one place, mirroring routes/api.php.
/// Paths are relative to [ApiConfig.apiBaseUrl] (which already ends in
/// `/api/v1`).
///
/// The list below is now a complete mirror of the player and trainer route
/// groups. The entries marked "added" were live on the backend but had no
/// constant here, which is why the app had no way to reach them:
/// payment-source selection at checkout, payment history, the player's own
/// enrollments, session ratings, the trainer's KPI and salary records, the
/// trainer's own memberships, the flat session list, and the shared
/// profile/avatar endpoints that every signed-in role has.
class ApiEndpoints {
  ApiEndpoints._();

  // --- Auth (public) ---
  static const register = '/register';
  static const login = '/login';
  static const logout = '/logout';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  /// Registration is two-step: /register issues an emailed code and no
  /// token, and /login refuses an unverified address. One of these has to
  /// succeed before the account can be used.
  static const verifyEmail = '/verify-email';
  static const resendVerification = '/resend-verification';

  /// Parent portal sign-in: a player's code in, a read-only token out.
  static const guardianLogin = '/guardian/login';

  /// The prefix every "the signed-in player's own data" route hangs off.
  ///
  /// A guardian token authenticates *as* the player it belongs to, and the
  /// backend registers a read-only mirror of the player routes under
  /// `/guardian`. Swapping the prefix here rather than duplicating every
  /// constant is what lets the player cubits, models and screens serve both
  /// sessions unchanged - the alternative was a parallel set of guardian
  /// cubits that would drift out of step the first time a player screen
  /// changed.
  ///
  /// Only read-only routes exist under `/guardian`. The write paths below
  /// (check-in, payments, ratings) keep the `/player` prefix on purpose:
  /// they are never reachable in a guardian session, and the UI hides them,
  /// but if one were ever called it should fail loudly against a route that
  /// does not exist for guardians rather than quietly appear to work.
  static String get _scope => AppScope.isGuardian ? '/guardian' : '/player';

  // --- Shared: any signed-in role ---
  static const me = '/user/me';
  static const users = '/user';
  static String user(int id) => '/user/$id';

  /// The shared "my account" surface. Distinct from `/player/profile` and
  /// `/trainer/profile`: those two edit role-specific fields, while this one
  /// is the only place that can change email, phone or password, and the
  /// only place that manages the avatar.
  static const profile = '/profile';
  static const profileAvatar = '/profile/avatar';

  // --- Player (and, through [_scope], the read-only parent portal) ---
  static String get playerHomepage => '$_scope/homepage';
  static String get playerSports => '$_scope/sports';
  static String get playerAttendances => '$_scope/attendances';
  static String get playerProfile => '$_scope/profile';
  static String playerMembership(int membershipId) =>
      '$_scope/memberships/$membershipId';
  static String get playerEnrollments => '$_scope/enrollments';

  /// Write path - stays on `/player` even in a guardian session. See the
  /// note on [_scope].
  static const playerSessionRatings = '/player/session-ratings';

  /// added - the club's online payment methods, already filtered server-side
  /// to active + online sources, so whatever comes back is safe to render as
  /// a choice at checkout.
  static const playerPaymentSources = '/player/payment-sources';

  static String get playerPayments => '$_scope/payments';
  static String playerPayment(int paymentId) => '$_scope/payments/$paymentId';
  static const playerPaymentsInitiate = '/player/payments/initiate';
  static String playerPaymentSimulate(int paymentId) => '/player/payments/$paymentId/simulate';
  static const playerCheckIn = '/player/check-in';

  // --- Guardian (parent portal) ---
  /// Mirrors `/user/me`, which a guardian token is refused on.
  static const guardianMe = '/guardian/me';
  static const guardianLogout = '/guardian/logout';

  // --- Trainer ---
  static const trainerHomepage = '/trainer/homepage';

  /// The board route is registered before the `{session}` wildcard on the
  /// backend so "board" isn't swallowed as an id. Keep them in this order
  /// here too, as a reminder of that constraint.
  static const trainerSessionsBoard = '/trainer/sessions/board';
  static const trainerSessions = '/trainer/sessions';
  static String trainerSession(int sessionId) => '/trainer/sessions/$sessionId';
  static String trainerSessionReschedule(int sessionId) =>
      '/trainer/sessions/$sessionId/reschedule';
  static String trainerSessionQr(int sessionId) => '/trainer/sessions/$sessionId/qr';
  static String trainerSessionQrRegenerate(int sessionId) =>
      '/trainer/sessions/$sessionId/qr/regenerate';

  static const trainerAttendances = '/trainer/attendances';
  static const trainerAttendancesScan = '/trainer/attendances/scan';

  static const trainerPlayers = '/trainer/players';
  static String trainerPlayer(int userId) => '/trainer/players/$userId';

  static const trainerProfile = '/trainer/profile';

  static const trainerKpiRecords = '/trainer/kpi-records';
  static const trainerSalaries = '/trainer/salaries';

  static const trainerMemberships = '/trainer/memberships';
  static String trainerMembership(int membershipId) => '/trainer/memberships/$membershipId';
  static String trainerGenerateSessions(int membershipId) =>
      '/trainer/memberships/$membershipId/generate-sessions';
}
