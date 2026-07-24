import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_app_check_config.dart';

class FirebaseInitializer {
  const FirebaseInitializer._();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      await _initializeAppCheck();
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _initializeAppCheck() async {
    final config = FirebaseAppCheckConfig.fromDotEnv();

    if (kIsWeb && kReleaseMode && !config.canUseWebAppCheck) {
      debugPrint(
        'Firebase App Check skipped: FIREBASE_RECAPTCHA_SITE_KEY is not set.',
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? const AppleAppAttestWithDeviceCheckFallbackProvider()
          : const AppleDebugProvider(),
      providerWeb: kReleaseMode
          ? ReCaptchaV3Provider(config.webRecaptchaSiteKey)
          : WebDebugProvider(),
    );
  }
}
