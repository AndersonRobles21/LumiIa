import 'package:flutter/material.dart';
import 'app_language.dart';
import 'dashboard_screen.dart';
import 'historial_ia_screen.dart';
import 'profile_screen.dart';

class AppBottomNavbar extends StatelessWidget {
  final String userId;

  /// 0 = Inicio (Dashboard), 1 = Calendario, 2 = IA/Historial, 3 = Perfil
  final int currentIndex;

  const AppBottomNavbar({
    super.key,
    required this.userId,
    required this.currentIndex,
  });

  void _goTo(BuildContext context, int index) {
    // Si ya estás en esa pantalla, no hacemos nada (evita apilar pantallas iguales).
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        // Vuelve al Dashboard limpiando el stack de navegación,
        // para no acumular pantallas repetidas.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardScreen(userId: userId)),
          (route) => false,
        );
        break;
      case 1:
        // Aún no existe una pantalla de Calendario en el proyecto.
        // Dejamos el botón funcional (con feedback) en vez de un ícono muerto.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLanguage.instance.t('nav_calendar_soon')),
            backgroundColor: const Color(0xFF2E1B4E),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistorialIAScreen(userId: userId),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1437),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(context, index: 0, icon: Icons.home),
            _navIcon(context, index: 1, icon: Icons.calendar_month_outlined),
            _navIcon(context, index: 2, icon: Icons.psychology_outlined),
            _navIcon(context, index: 3, icon: Icons.person_outline),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(
    BuildContext context, {
    required int index,
    required IconData icon,
  }) {
    final bool active = index == currentIndex;
    return GestureDetector(
      onTap: () => _goTo(context, index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: active ? const Color(0xFFFF44AA) : Colors.white38,
          size: 24,
        ),
      ),
    );
  }
}