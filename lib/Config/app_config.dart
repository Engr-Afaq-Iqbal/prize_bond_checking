class AppConfig {
  /// Application Name
  static String appName = '';
  static String tokenExpiryTime = "3600";

  static String blomalLogoUrl = '';
  static String imgUrl = 'assets/images/';

  static int timerSeconds = int.parse(
    '120',
  ); //2 minutes = 120 seconds

  // static int fileSizeInMB = int.parse(dotenv.env['FILE_SIZE_IN_MB'] ?? '');
}
