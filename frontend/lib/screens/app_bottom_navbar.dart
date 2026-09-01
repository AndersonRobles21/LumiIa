import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '/services/api_service.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'historial_ia_screen.dart';
import 'progreso_screen.dart';
import 'profile_screen.dart';

class AppBottomNavbar extends StatelessWidget {
  final String userId;
  final int currentIndex;

  const AppBottomNavbar({
    super.key,
    required this.userId,
    required this.currentIndex,
  });

  Future<void> _goTo(BuildContext context, int index) async {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        // Dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardScreen(userId: userId)),
          (route) => false,
        );
        break;

      case 1:
        // Calendario 
        final tasks = await ApiService.getPlanesEstudio(userId) ?? [];
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CalendarScreen(userId: userId, tasks: tasks),
          ),
        );
        break;

      case 2:
        // Historial IA
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HistorialIAScreen(userId: userId),
          ),
        );
        break;

      case 3:
        // Progreso (Gráfica)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProgresoScreen(userId: userId),
          ),
        );
        break;

      case 4:
        // Perfil
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: userId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: Responsive.altoBoton(context) + 12,
        margin: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: Responsive.espacio(context)),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1437),
          borderRadius: BorderRadius.circular(Responsive.radioBorde(context) * 2),
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
            _navIcon(context, index: 3, icon: Icons.bar_chart_rounded),
            _navIcon(context, index: 4, icon: Icons.person_outline),
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
        padding: EdgeInsets.all(Responsive.espacio(context)),
        child: Icon(
          icon,
          color: active ? const Color(0xFFFF44AA) : Colors.white38,
          size: Responsive.tamanioSubtitulo(context),
        ),
      ),
    );
  }
}