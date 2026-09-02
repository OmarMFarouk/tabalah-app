/// Named routes used with Navigator's named-route API. Most navigation in
/// this app pushes views directly (MaterialPageRoute) since several views
/// take required constructor arguments (e.g. LoginView(loginType: ...)),
/// but keeping a few well-known top-level names here is still useful for
/// deep-linking / analytics route names.
class AppRoutes {
  AppRoutes._();

  static const String onboarding = 'onboarding';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String register = 'register';
  static const String playerHome = 'player_home';
  static const String trainerHome = 'trainer_home';
}
