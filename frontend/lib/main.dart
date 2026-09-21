import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/configuracion_screen.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/services/theme_controller.dart';
import 'package:frontend/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://lsbnizzypdmnvppatzxp.supabase.co',
      anonKey: 'sb_publishable_KK0lsvy3EBB8WuHVg2zOiA_WOeJs6RZ', // pega tu llave completa aquí
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
    print("✅ Supabase inicializado correctamente.");
  } catch (e) {
    print("⚠️ Supabase ya se encontraba inicializado o dio un aviso: $e");
  }

  await ThemeController.instance.initialize();
  runApp(const LumiApp());
}

class LumiApp extends StatefulWidget {
  const LumiApp({super.key});

  @override
  State<LumiApp> createState() => _LumiAppState();
}

class _LumiAppState extends State<LumiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSession();
    }
  }

  Future<void> _refreshSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) return;

    try {
      await auth.refreshSession();
    } on AuthException catch (error) {
      debugPrint('No se pudo renovar la sesión: ${error.message}');
    } catch (error) {
      debugPrint('Error renovando la sesión: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumi IA',
      debugShowCheckedModeBanner: false,
      theme: LumiAppTheme.light,
      darkTheme: LumiAppTheme.dark,
      themeMode: ThemeController.instance.themeMode,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/configuracion': (context) => const ConfiguracionScreen(),
        '/admin-panel': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId']?.toString() ?? '';
          return AdminPanelScreen(userId: userId);
        },
      },
    );
  }
}