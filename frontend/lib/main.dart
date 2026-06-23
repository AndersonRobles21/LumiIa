import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/login_screen.dart'; // Tu pantalla de login oficial

void main() async {
  // 1. Obligatorio para inicializar servicios antes de montar la UI
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Inicializamos la instancia limpia con tus credenciales reales
    await Supabase.initialize(
      url: 'https://lsbnizzypdmnvppatzxp.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzYm5penp5cGRtbnZwcGF0enhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExOTE1MTEsImV4cCI6MjA5Njc2NzUxMX0.BSPlhX0JOwUWTYoSmzcse3MAIANgu5UniSNxm6Qjr0U', // Pon aquí tu llave larga completa si está cortada
    );
    print("✅ Supabase inicializado correctamente.");
  } catch (e) {
    // Si ya estaba inicializado de una ejecución anterior, evita que la app se caiga
    print("⚠️ Supabase ya se encontraba inicializado o dio un aviso: $e");
  }

  // 3. Montamos la aplicación
  runApp(const IniciarSesion());
}

class IniciarSesion extends StatelessWidget {
  const IniciarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iniciar Sesión',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}
// Abajo de esto dejas el resto de tu código normal (la clase IniciarSesion, etc.)