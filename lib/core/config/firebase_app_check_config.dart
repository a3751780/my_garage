import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseAppCheckConfig {
  const FirebaseAppCheckConfig({
    required this.webRecaptchaSiteKey,
  });

  factory FirebaseAppCheckConfig.fromDotEnv() {
    const webRecaptchaSiteKeyFromEnvironment =
        String.fromEnvironment('FIREBASE_RECAPTCHA_SITE_KEY');
    final webRecaptchaSiteKey =
        dotenv.env['FIREBASE_RECAPTCHA_SITE_KEY']?.trim().isNotEmpty == true
            ? dotenv.env['FIREBASE_RECAPTCHA_SITE_KEY']!
            : webRecaptchaSiteKeyFromEnvironment;

    return FirebaseAppCheckConfig(
      webRecaptchaSiteKey: webRecaptchaSiteKey,
    );
  }

  final String webRecaptchaSiteKey;

  bool get canUseWebAppCheck => webRecaptchaSiteKey.trim().isNotEmpty;
}
