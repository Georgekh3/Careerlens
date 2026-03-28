import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/services/profile_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/resume_entry_screen.dart';
import 'features/auth/presentation/screens/upload_cv_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const CareerLensApp());
}

class CareerLensApp extends StatelessWidget {
  const CareerLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E4EA8)),
      ),
      home: const _AuthBootstrap(),
    );
  }
}

class _AuthBootstrap extends StatelessWidget {
  const _AuthBootstrap();

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const LoginScreen();
    }

    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, client.auth.currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? client.auth.currentSession;
        if (session != null) {
          return const _SignedInHome();
        }
        return const LoginScreen();
      },
    );
  }
}

class _SignedInHome extends StatelessWidget {
  const _SignedInHome();

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return FutureBuilder<bool>(
      future: profileService.hasExistingProfileData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasExistingProfile = snapshot.data ?? false;
        return ResumeEntryScreen(hasExistingProfile: hasExistingProfile);
      },
    );
  }
}
