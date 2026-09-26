import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '/services/api_service.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'historial_ia_screen.dart';
import 'progreso_screen.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';

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
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: LumiAppTheme.surface(context),
            border: Border(
              right: BorderSide(color: LumiAppTheme.outline(context)),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.black12,
                blurRadius: 16,
                offset: Offset(5, 0),
              ),
            ],
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrand(context),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'NAVEGACIÓN',
                      style: TextStyle(
                        color: LumiAppTheme.secondaryText(context),
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
                  const SizedBox(height: 18),
                  Divider(color: LumiAppTheme.outline(context), height: 1),
                  const SizedBox(height: 14),
                  _buildSidebarIllustration(context),
                ],
              ),
            ),
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
          color: LumiAppTheme.surface(context),
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

  Widget _buildBrand(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: LumiAppTheme.surfaceVariant(context),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: LumiAppTheme.outline(context)),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LUMI',
              style: TextStyle(
                color: LumiAppTheme.primaryText(context),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            Text(
              'Estudia mejor',
              style: TextStyle(color: LumiAppTheme.secondaryText(context), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebarIllustration(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: LumiAppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LumiAppTheme.outline(context)),
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
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? LumiAppTheme.accent(context).withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: active
                ? Border(
                    left: BorderSide(
                      color: LumiAppTheme.accent(context),
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? LumiAppTheme.accent(context).withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: active
                      ? LumiAppTheme.accent(context)
                      : LumiAppTheme.secondaryText(context),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? LumiAppTheme.primaryText(context)
                        : LumiAppTheme.secondaryText(context),
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (active)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: LumiAppTheme.accent(context),
                    shape: BoxShape.circle,
                  ),
                ),
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
          color: active ? LumiAppTheme.accent(context) : LumiAppTheme.secondaryText(context),
          size: Responsive.tamanioSubtitulo(context),
        ),
      ),
    );
  }
}