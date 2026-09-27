import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'app_language.dart';

/// Un bloque de contenido dentro de InfoScreen.
/// Si [items] viene lleno, se pinta como una lista tipo FAQ (acordeón).
/// Si no, se pinta como texto simple (parrafo).
class InfoSection {
  final String heading;
  final String? body;
  final List<MapEntry<String, String>>? items; // pregunta -> respuesta

  const InfoSection({required this.heading, this.body, this.items});
}

class InfoScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<InfoSection> sections;

  const InfoScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.sections,
  });

  // ---- Colores consistentes con el resto de la app ----
  static const Color bgDark = Color(0xFF0B0813);
  static const Color cardColor = Color(0xFF1F1A3A);
  static const Color accentPink = Color(0xFFFF44AA);
  static const Color textGrey = Color(0xFFB0AEC4);
  static const Map<String, String> _englishText = {
    'Privacidad y datos': 'Privacy & data',
    'Qué datos guarda Lumi': 'What data Lumi stores',
    'Guardamos lo necesario para armar tu plan de estudio: tu nombre, tu perfil de estudio (objetivo, horas disponibles, nivel de procrastinación), tus horarios, tus planes, actividades y tareas, y tu historial de conversaciones con la IA de Lumi.':
        'We store what is needed to create your study plan: your name, study profile (goal, available hours, and procrastination level), schedule, plans, activities, tasks, and conversation history with Lumi AI.',
    'Dónde se guardan': 'Where your data is stored',
    'Toda tu información vive en Supabase, con autenticación segura. Nadie puede entrar a tu cuenta sin tu correo y contraseña.':
        'Your information is stored in Supabase with secure authentication. No one can access your account without your email and password.',
    'Cómo se usan tus datos': 'How your data is used',
    'Usamos tu información únicamente para generar tus planes de estudio, mostrarte tus estadísticas y personalizar las respuestas de la IA. No vendemos ni compartimos tus datos con terceros.':
        'We use your information only to create study plans, show your statistics, and personalize AI responses. We do not sell or share your data with third parties.',
    'Tus derechos': 'Your rights',
    'Puedes pedir la eliminación de tu cuenta y de todos tus datos cuando quieras escribiendo a soporte. También puedes editar o corregir tu información desde tu perfil en cualquier momento.':
        'You can request deletion of your account and all your data at any time by contacting support. You can also edit or correct your information from your profile at any time.',
    'Centro de ayuda': 'Help center',
    'Preguntas frecuentes': 'Frequently asked questions',
    '¿Cómo creo un plan de estudio?': 'How do I create a study plan?',
    'Ve a la sección de Planes y toca "Nuevo plan". Ponle un nombre, elige tus métodos de estudio favoritos y Lumi te ayuda a organizar las actividades.':
        'Go to Plans and tap “New plan.” Give it a name, choose your favorite study methods, and Lumi will help organize the activities.',
    '¿Cómo edito mi horario disponible?': 'How do I edit my availability?',
    'Entra a tu Perfil, baja hasta "Horario semanal" y toca el día que quieras editar para agregar o quitar bloques de tiempo.':
        'Open your Profile, scroll to “Weekly schedule,” and tap a day to add or remove time blocks.',
    '¿Para qué sirve la IA de Lumi?': 'What can Lumi AI do?',
    'Le puedes preguntar cómo organizar tu tiempo, pedirle consejos de técnicas de estudio o resolver dudas sobre tu plan actual. Todo tu historial queda guardado para que puedas volver a revisarlo.':
        'Ask it how to organize your time, get study technique tips, or ask questions about your current plan. Your history is saved so you can review it later.',
    '¿Cómo gano recompensas?': 'How do I earn rewards?',
    'Cada tarea que completas suma a tus estadísticas. Al alcanzar ciertas metas (rachas, tareas completadas) desbloqueas recompensas dentro de la app.':
        'Each completed task adds to your statistics. Reach goals (streaks or completed tasks) to unlock rewards in the app.',
    '¿No encontraste tu respuesta?': 'Didn’t find your answer?',
    'Escríbenos a soporte.lumi@gmail.com y te ayudamos.':
        'Email us at soporte.lumi@gmail.com and we’ll help you.',
    'Acerca de Lumi': 'About Lumi',
    'Lumi IA': 'Lumi AI',
    'Versión': 'Version',
    'Hecho con': 'Made with',
    'Lumi es tu asistente de estudio: te ayuda a organizar tu tiempo, crear planes personalizados y mantener la constancia con recordatorios, estadísticas y recompensas.':
        'Lumi is your study assistant: it helps you organize your time, create personalized plans, and stay consistent with reminders, statistics, and rewards.',
    'Flutter y Supabase.': 'Flutter and Supabase.',
  };

  String _localized(String spanish) =>
      AppLanguage.instance.isEnglish
          ? _englishText[spanish] ?? spanish
          : spanish;

  // -----------------------------------------------------------------
  // CONTENIDO PREDEFINIDO — listo para usar desde ConfiguracionScreen
  // -----------------------------------------------------------------
  factory InfoScreen.privacidad() {
    return const InfoScreen(
      title: 'Privacidad y datos',
      icon: Icons.privacy_tip_outlined,
      sections: [
        InfoSection(
          heading: 'Qué datos guarda Lumi',
          body:
              'Guardamos lo necesario para armar tu plan de estudio: tu nombre, '
              'tu perfil de estudio (objetivo, horas disponibles, nivel de '
              'procrastinación), tus horarios, tus planes, actividades y tareas, '
              'y tu historial de conversaciones con la IA de Lumi.',
        ),
        InfoSection(
          heading: 'Dónde se guardan',
          body:
              'Toda tu información vive en Supabase, con autenticación segura. '
              'Nadie puede entrar a tu cuenta sin tu correo y contraseña.',
        ),
        InfoSection(
          heading: 'Cómo se usan tus datos',
          body:
              'Usamos tu información únicamente para generar tus planes de '
              'estudio, mostrarte tus estadísticas y personalizar las '
              'respuestas de la IA. No vendemos ni compartimos tus datos con '
              'terceros.',
        ),
        InfoSection(
          heading: 'Tus derechos',
          body:
              'Puedes pedir la eliminación de tu cuenta y de todos tus datos '
              'cuando quieras escribiendo a soporte. También puedes editar o '
              'corregir tu información desde tu perfil en cualquier momento.',
        ),
      ],
    );
  }

  factory InfoScreen.ayuda() {
    return const InfoScreen(
      title: 'Centro de ayuda',
      icon: Icons.help_outline,
      sections: [
        InfoSection(
          heading: 'Preguntas frecuentes',
          items: [
            MapEntry(
              '¿Cómo creo un plan de estudio?',
              'Ve a la sección de Planes y toca "Nuevo plan". Ponle un nombre, '
                  'elige tus métodos de estudio favoritos y Lumi te ayuda a '
                  'organizar las actividades.',
            ),
            MapEntry(
              '¿Cómo edito mi horario disponible?',
              'Entra a tu Perfil, baja hasta "Horario semanal" y toca el día '
                  'que quieras editar para agregar o quitar bloques de tiempo.',
            ),
            MapEntry(
              '¿Para qué sirve la IA de Lumi?',
              'Le puedes preguntar cómo organizar tu tiempo, pedirle consejos '
                  'de técnicas de estudio o resolver dudas sobre tu plan '
                  'actual. Todo tu historial queda guardado para que puedas '
                  'volver a revisarlo.',
            ),
            MapEntry(
              '¿Cómo gano recompensas?',
              'Cada tarea que completas suma a tus estadísticas. Al alcanzar '
                  'ciertas metas (rachas, tareas completadas) desbloqueas '
                  'recompensas dentro de la app.',
            ),
          ],
        ),
        InfoSection(
          heading: '¿No encontraste tu respuesta?',
          body: 'Escríbenos a soporte.lumi@gmail.com y te ayudamos.',
        ),
      ],
    );
  }

  factory InfoScreen.acercaDe() {
    return const InfoScreen(
      title: 'Acerca de Lumi',
      icon: Icons.info_outline,
      sections: [
        InfoSection(
          heading: 'Lumi IA',
          body:
              'Lumi es tu asistente de estudio: te ayuda a organizar tu '
              'tiempo, crear planes personalizados y mantener la constancia '
              'con recordatorios, estadísticas y recompensas.',
        ),
        InfoSection(
          heading: 'Versión',
          body: '1.0.0',
        ),
        InfoSection(
          heading: 'Hecho con',
          body: 'Flutter y Supabase.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1D8A), Color(0xFF16003A), Color(0xFF080010)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.anchoMaximoContenido(context)),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.paddingHorizontalRecomendado(context),
                        vertical: Responsive.espacio(context),
                      ),
                      children: [
                        for (final section in sections) _buildSection(context, section),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: LumiAppTheme.primaryText(context)),
            onPressed: () => Navigator.pop(context),
          ),
          Icon(icon, color: accentPink, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
            _localized(title),
              style: GoogleFonts.orbitron(
                color: LumiAppTheme.primaryText(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, InfoSection section) {
    if (section.items != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading(section.heading),
            const SizedBox(height: 6),
            ...section.items!.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: LumiAppTheme.surface(context).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF321438), width: 1),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: accentPink,
                    collapsedIconColor: textGrey,
                    title: Text(
                      _localized(item.key),
                      style: GoogleFonts.orbitron(
                        color: LumiAppTheme.primaryText(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localized(item.value),
                        style: GoogleFonts.orbitron(
                          color: textGrey,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF321438), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(section.heading),
          const SizedBox(height: 8),
          Text(
            _localized(section.body ?? ''),
            style: GoogleFonts.orbitron(
              color: textGrey,
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Text(
      _localized(text),
      style: GoogleFonts.orbitron(
        color: accentPink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}