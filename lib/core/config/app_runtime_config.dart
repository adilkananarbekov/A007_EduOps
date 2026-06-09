import '../api/api_constants.dart';

class AppRuntimeConfig {
  AppRuntimeConfig._();

  static const bool isTestMode = bool.fromEnvironment(
    'EDUOPS_TEST_MODE',
    defaultValue: false,
  );

  static const bool enableDemoLogin = bool.fromEnvironment(
    'EDUOPS_ENABLE_DEMO_LOGIN',
    defaultValue: false,
  );

  static bool get showDemoTools => isTestMode || enableDemoLogin;

  static String get environmentLabel => isTestMode ? 'TEST MODE' : 'PROD';

  static String get apiBaseUrl => ApiConstants.baseApiUrl;
}
