import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/configuracion_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://lsbnizzypdmnvppatzxp.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzYm5penp5cGRtbnZwcGF0enhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExOTE1MTEsImV4cCI6MjA5Njc2NzUxMX0.BSPlhX0JOwUWTYoSmzcse3MAIANgu5UniSNxm6Qjr0U', // pega tu llave completa aquí
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
      },
    );
  }
}