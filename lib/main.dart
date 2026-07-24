import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/firebase_initializer.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/garage/presentation/garage_home_page.dart';
import 'shared/providers/supabase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await FirebaseInitializer.initialize();

  // 如果要推到web用的
  // await dotenv.load(
  //   isOptional: true,
  //   mergeWith: const {
  //     'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
  //     'SUPABASE_PUBLISHABLE_KEY': String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  //     'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
  //   },
  // );

  final supabaseConfig = SupabaseConfig.fromDotEnv();
  if (supabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: supabaseConfig.url,
      publishableKey: supabaseConfig.publishableKey,
    );
  }

  runApp(const ProviderScope(child: MyGarageApp()));
}

class MyGarageApp extends ConsumerWidget {
  const MyGarageApp({super.key});

  static const _backgroundColor = Color(0xFFFFFFFF);
  static const _floatingButtonColor = Color(0xFF0072E3);
  static const _toolbarColor = Color(0xFF009FCC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'My Garage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _floatingButtonColor),
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: _toolbarColor,
          surfaceTintColor: _toolbarColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _floatingButtonColor,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.watch(authSessionProvider);

    return authSession.when(
      data: (session) {
        if (session == null) {
          return const LoginPage();
        }

        return const GarageHomePage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginPage(),
    );
  }
}
