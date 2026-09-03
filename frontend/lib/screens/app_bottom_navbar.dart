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
    if (Responsive.esEscritorio(context)) {
      return SizedBox(
        width: Responsive.anchoSidebar(context),
        height: double.infinity,
        child: Container(
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 18),
          decoration: const BoxDecoration(
            color: Color(0xFF15112E),
            border: Border(right: BorderSide(color: Color(0xFF33285D))),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(5, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBrand(),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 10),
                child: Text(
                  'NAVEGACIÓN',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              _navItem(context, index: 0, icon: Icons.home, label: 'Inicio'),
              _navItem(context, index: 1, icon: Icons.calendar_month_outlined, label: 'Calendario'),
              _navItem(context, index: 2, icon: Icons.psychology_outlined, label: 'Historial IA'),
              _navItem(context, index: 3, icon: Icons.bar_chart_rounded, label: 'Progreso'),
              _navItem(context, index: 4, icon: Icons.person_outline, label: 'Perfil'),
              const Spacer(),
              _buildSidebarIllustration(),
            ],
          ),
        ),
      );
    }

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

  Widget _buildBrand() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1F5A),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF6D43D9)),
          ),
          child: Image.asset(
            'logo/chat_ia.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.psychology,
              color: Color(0xFFFF44AA),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LUMI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            Text(
              'Estudia mejor',
              style: TextStyle(color: Color(0xFFAAA2C9), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebarIllustration() {
    return Container(
      height: 170,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF211A42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF33285D)),
      ),
      child: Image.asset(
        'logo/tarea.png',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.task_alt,
          color: Color(0xFFFF44AA),
          size: 52,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    if (!Responsive.esEscritorio(context)) {
      return _navIcon(context, index: index, icon: icon);
    }

    final active = index == currentIndex;
    return InkWell(
      onTap: () => _goTo(context, index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF342263) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? const Border(left: BorderSide(color: Color(0xFFFF44AA), width: 3))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, color: active ? const Color(0xFFFF44AA) : Colors.white54, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (active)
              const Icon(Icons.chevron_right, color: Color(0xFFFF44AA), size: 17),
          ],
          ),
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