import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/configuracion_screen.dart';
import 'package:frontend/screens/admin_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://lsbnizzypdmnvppatzxp.supabase.co',
      anonKey: 'sb_publishable_KK0lsvy3EBB8WuHVg2zOiA_WOeJs6RZ', // pega tu llave completa aquí
    );
    print("✅ Supabase inicializado correctamente.");
  } catch (e) {
    print("⚠️ Supabase ya se encontraba inicializado o dio un aviso: $e");
  }

  runApp(const LumiApp());
}

class LumiApp extends StatelessWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumi IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D2B),
      ),
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