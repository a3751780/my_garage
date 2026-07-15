import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

final supabaseConfigProvider = Provider<SupabaseConfig>((ref) {
  return SupabaseConfig.fromDotEnv();
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final config = ref.watch(supabaseConfigProvider);

  if (!config.isConfigured) {
    throw StateError(
      'Supabase is not configured. Add SUPABASE_URL and '
      'SUPABASE_PUBLISHABLE_KEY to your .env file.',
    );
  }

  return Supabase.instance.client;
});

final authSessionProvider = StreamProvider<Session?>((ref) {
  final config = ref.watch(supabaseConfigProvider);

  if (!config.isConfigured) {
    return Stream<Session?>.value(null);
  }

  final client = ref.watch(supabaseClientProvider);

  return client.auth.onAuthStateChange.map((event) => event.session);
});
