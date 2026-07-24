import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleMapsConfig {
  const GoogleMapsConfig({
    required this.placesApiKey,
  });

  factory GoogleMapsConfig.fromDotEnv() {
    const placesApiKeyFromEnvironment =
        String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    const mapsApiKeyFromEnvironment =
        String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    final placesApiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ??
        dotenv.env['GOOGLE_MAPS_API_KEY'] ??
        placesApiKeyFromEnvironment.ifNotEmpty ??
        mapsApiKeyFromEnvironment;

    return GoogleMapsConfig(placesApiKey: placesApiKey);
  }

  final String placesApiKey;

  bool get canUsePlaces => placesApiKey.trim().isNotEmpty;
}

extension on String {
  String? get ifNotEmpty => isEmpty ? null : this;
}
