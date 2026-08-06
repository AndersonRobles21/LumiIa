import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Qué contenido predefinido debe mostrar InfoScreen. El texto real se
/// resuelve en tiempo de construcción según el idioma actual, para que la
/// pantalla cambie de idioma en caliente igual que el resto de la app.
enum _InfoKind { privacidad, ayuda, acercaDe }

class InfoScreen extends StatefulWidget {
  final _InfoKind _kind;

  const InfoScreen._(this._kind, {super.key});

  factory InfoScreen.privacidad({Key? key}) =>
      InfoScreen._(_InfoKind.privacidad, key: key);

  factory InfoScreen.ayuda({Key? key}) =>
      InfoScreen._(_InfoKind.ayuda, key: key);

  factory InfoScreen.acercaDe({Key? key}) =>
      InfoScreen._(_InfoKind.acercaDe, key: key);

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen>
    with AppLanguageListenerMixin<InfoScreen> {
  // ---- Colores consistentes con el resto de la app ----
  static const Color bgDark = Color(0xFF0B0813);
  static const Color cardColor = Color(0xFF1F1A3A);
  static const Color accentPink = Color(0xFFFF44AA);
  static const Color textGrey = Color(0xFFB0AEC4);

  String get _title {
    switch (widget._kind) {
      case _InfoKind.privacidad:
        return tr('Privacidad y datos', 'Privacy & data');
      case _InfoKind.ayuda:
        return tr('Centro de ayuda', 'Help center');
      case _InfoKind.acercaDe:
        return tr('Acerca de Lumi', 'About Lumi');
    }
  }

  IconData get _icon {
    switch (widget._kind) {
      case _InfoKind.privacidad:
        return Icons.privacy_tip_outlined;
      case _InfoKind.ayuda:
        return Icons.help_outline;
      case _InfoKind.acercaDe:
        return Icons.info_outline;
    }
  }

  List<InfoSection> get _sections {
    switch (widget._kind) {
      case _InfoKind.privacidad:
        return [
          InfoSection(
            heading: tr('Qué datos guarda Lumi', 'What data Lumi stores'),
            body: tr(
              'Guardamos lo necesario para armar tu plan de estudio: tu nombre, '
                  'tu perfil de estudio (objetivo, horas disponibles, nivel de '
                  'procrastinación), tus horarios, tus planes, actividades y tareas, '
                  'y tu historial de conversaciones con la IA de Lumi.',
              'We store what\'s needed to build your study plan: your name, '
                  'your study profile (goal, available hours, procrastination '
                  'level), your schedules, plans, activities and tasks, and '
                  'your conversation history with Lumi\'s AI.',
            ),
          ),
          InfoSection(
            heading: tr('Dónde se guardan', 'Where it\'s stored'),
            body: tr(
              'Toda tu información vive en Supabase, con autenticación segura. '
                  'Nadie puede entrar a tu cuenta sin tu correo y contraseña.',
              'All your information lives in Supabase, with secure '
                  'authentication. No one can access your account without your '
                  'email and password.',
            ),
          ),
          InfoSection(
            heading: tr('Cómo se usan tus datos', 'How your data is used'),
            body: tr(
              'Usamos tu información únicamente para generar tus planes de '
                  'estudio, mostrarte tus estadísticas y personalizar las '
                  'respuestas de la IA. No vendemos ni compartimos tus datos con '
                  'terceros.',
              'We use your information only to generate your study plans, '
                  'show you your statistics, and personalize the AI\'s '
                  'responses. We don\'t sell or share your data with third '
                  'parties.',
            ),
          ),
          InfoSection(
            heading: tr('Tus derechos', 'Your rights'),
            body: tr(
              'Puedes pedir la eliminación de tu cuenta y de todos tus datos '
                  'cuando quieras escribiendo a soporte. También puedes editar o '
                  'corregir tu información desde tu perfil en cualquier momento.',
              'You can request the deletion of your account and all your data '
                  'at any time by writing to support. You can also edit or '
                  'correct your information from your profile at any time.',
            ),
          ),
        ];
      case _InfoKind.ayuda:
        return [
          InfoSection(
            heading: tr('Preguntas frecuentes', 'Frequently asked questions'),
            items: [
              MapEntry(
                tr('¿Cómo creo un plan de estudio?', 'How do I create a study plan?'),
                tr(
                  'Ve a la sección de Planes y toca "Nuevo plan". Ponle un nombre, '
                      'elige tus métodos de estudio favoritos y Lumi te ayuda a '
                      'organizar las actividades.',
                  'Go to the Plans section and tap "New plan". Give it a name, '
                      'choose your favorite study methods, and Lumi will help you '
                      'organize the activities.',
                ),
              ),
              MapEntry(
                tr('¿Cómo edito mi horario disponible?', 'How do I edit my available schedule?'),
                tr(
                  'Entra a tu Perfil, baja hasta "Horario semanal" y toca el día '
                      'que quieras editar para agregar o quitar bloques de tiempo.',
                  'Go to your Profile, scroll down to "Weekly schedule" and tap '
                      'the day you want to edit to add or remove time blocks.',
                ),
              ),
              MapEntry(
                tr('¿Para qué sirve la IA de Lumi?', 'What is Lumi\'s AI for?'),
                tr(
                  'Le puedes preguntar cómo organizar tu tiempo, pedirle consejos '
                      'de técnicas de estudio o resolver dudas sobre tu plan '
                      'actual. Todo tu historial queda guardado para que puedas '
                      'volver a revisarlo.',
                  'You can ask it how to organize your time, ask for study '
                      'technique tips, or resolve questions about your current '
                      'plan. Your whole history is saved so you can review it '
                      'again later.',
                ),
              ),
              MapEntry(
                tr('¿Cómo gano recompensas?', 'How do I earn rewards?'),
                tr(
                  'Cada tarea que completas suma a tus estadísticas. Al alcanzar '
                      'ciertas metas (rachas, tareas completadas) desbloqueas '
                      'recompensas dentro de la app.',
                  'Every task you complete adds to your statistics. When you '
                      'reach certain goals (streaks, completed tasks) you unlock '
                      'rewards inside the app.',
                ),
              ),
            ],
          ),
          InfoSection(
            heading: tr('¿No encontraste tu respuesta?', 'Didn\'t find your answer?'),
            body: tr(
              'Escríbenos a soporte.lumi@gmail.com y te ayudamos.',
              'Write to us at soporte.lumi@gmail.com and we\'ll help you.',
            ),
          ),
        ];
      case _InfoKind.acercaDe:
        return [
          InfoSection(
            heading: 'Lumi IA',
            body: tr(
              'Lumi es tu asistente de estudio: te ayuda a organizar tu '
                  'tiempo, crear planes personalizados y mantener la constancia '
                  'con recordatorios, estadísticas y recompensas.',
              'Lumi is your study assistant: it helps you organize your time, '
                  'create personalized plans, and stay consistent with '
                  'reminders, statistics, and rewards.',
            ),
          ),
          InfoSection(
            heading: tr('Versión', 'Version'),
            body: '1.0.0',
          ),
          InfoSection(
            heading: tr('Hecho con', 'Built with'),
            body: 'Flutter y Supabase.',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
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
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      children: [
                        for (final section in _sections) _buildSection(section),
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Icon(_icon, color: accentPink, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _title,
              style: GoogleFonts.orbitron(
                color: Colors.white,
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

  Widget _buildSection(InfoSection section) {
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
                  color: cardColor.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF321438), width: 1),
                ),
                child: Theme(
                  data: ThemeData(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: accentPink,
                    collapsedIconColor: textGrey,
                    title: Text(
                      item.key,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
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
        color: cardColor.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF321438), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(section.heading),
          const SizedBox(height: 8),
          Text(
            section.body ?? '',
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
      text,
      style: GoogleFonts.orbitron(
        color: accentPink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
