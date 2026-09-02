/// Every bundled asset path, in one place, so a renamed/moved asset file
/// only needs a one-line update here.
class AppAssets {
  AppAssets._();

  static const String _imagesBase = 'assets/images';

  /// The club crest. Gold on transparent, so one file serves both themes.
  static const String logo = '$_imagesBase/logo.png';

  static const String onboardOne = '$_imagesBase/onboard_one.png';
  static const String onboardTwo = '$_imagesBase/onboard_two.png';
  static const String onboardThree = '$_imagesBase/onboard_three.png';
}
