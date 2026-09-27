import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_language.dart';

class SeleccionarMetodoScreen extends StatefulWidget {
  final String tituloTarea;
  final String metodoRecomendado;
  final Function(String metodoSeleccionado) onMetodoSeleccionado;

  const SeleccionarMetodoScreen({
    super.key,
    required this.tituloTarea,
    this.metodoRecomendado = 'Método Feynman',
    required this.onMetodoSeleccionado,
  });

  @override
  State<SeleccionarMetodoScreen> createState() =>
      _SeleccionarMetodoScreenState();
}

class _SeleccionarMetodoScreenState extends State<SeleccionarMetodoScreen>
    with AppLanguageListenerMixin<SeleccionarMetodoScreen> {
  late String _metodoActual;

  final List<Map<String, dynamic>> _metodos = [
    {
      'id': 'Método Feynman',
      'tituloEs': 'Método Feynman',
      'tituloEn': 'Feynman Method',
      'subtituloEs': 'Explica para aprender',
      'subtituloEn': 'Explain to learn',
      'descripcionEs':
          'Si no puedes explicarlo de forma sencilla, no lo has entendido bien.',
      'descripcionEn':
          'If you cannot explain it simply, you have not understood it well.',
      'icono': Icons.lightbulb,
      'colorIcono': Colors.amber,
    },
    {
      'id': 'Técnica Pomodoro',
      'tituloEs': 'Técnica Pomodoro',
      'tituloEn': 'Pomodoro Technique',
      'subtituloEs': 'Gestión del tiempo',
      'subtituloEn': 'Time management',
      'descripcionEs':
          'Alterna bloques de estudio intenso con descansos cortos.',
      'descripcionEn':
          'Alternate focused study sessions with short breaks.',
      'icono': Icons.timer_outlined,
      'colorIcono': const Color(0xFF00F0FF),
    },
    {
      'id': 'Active Recall',
      'tituloEs': 'Active Recall',
      'tituloEn': 'Active Recall',
      'subtituloEs': 'Recordatorio activo',
      'subtituloEn': 'Active recall',
      'descripcionEs':
          'Fuerza a tu cerebro a recuperar información de la memoria sin ayuda.',
      'descripcionEn':
          'Train your brain to retrieve information from memory without help.',
      'icono': Icons.psychology,
      'colorIcono': const Color(0xFFFF44AA),
    },
    {
      'id': 'Spaced Repetition',
      'tituloEs': 'Spaced Repetition',
      'tituloEn': 'Spaced Repetition',
      'subtituloEs': 'Repetición espaciada',
      'subtituloEn': 'Spaced repetition',
      'descripcionEs':
          'Repasa los temas en intervalos de tiempo crecientes para consolidar la memoria.',
      'descripcionEn':
          'Review topics at increasing intervals to strengthen your memory.',
      'icono': Icons.calendar_month,
      'colorIcono': Colors.orangeAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _metodoActual = widget.metodoRecomendado;
  }

  void _seleccionar(String id) {
    setState(() => _metodoActual = id);
    widget.onMetodoSeleccionado(id);

    if (mounted) {
      Navigator.pop(context, id);
    }
  }

  bool _esElRecomendado(String idMetodo) {
    final recomendado = widget.metodoRecomendado.toLowerCase();
    final id = idMetodo.toLowerCase();

    return recomendado.contains(id) || id.contains(recomendado);
  }

  @override
  Widget build(BuildContext context) {
    final anchoImagen = Responsive.anchoImagenMetodo(context);

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: LumiAppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: LumiAppTheme.primaryText(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: LumiAppTheme.surfaceVariant(context),
              child: ClipOval(
                child: Image.asset(
                  'logo/chat_ia.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.smart_toy,
                    color: Color(0xFF00F0FF),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.tituloTarea,
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        tr('Métodos de estudio', 'Study methods'),
                        style: TextStyle(
                          color: LumiAppTheme.primaryText(context),
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(
                          'Selecciona el método que mejor se adapte a tu objetivo actual.',
                          'Choose the method that best fits your current goal.',
                        ),
                        style: TextStyle(
                          color: LumiAppTheme.secondaryText(context),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: anchoImagen,
                  height: anchoImagen,
                  child: Image.asset(
                    'logo/metodos.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.smart_toy,
                      color: Color(0xFF00F0FF),
                      size: 110,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ..._metodos.map((metodo) {
              final id = metodo['id'] as String;
              final esRecomendado = _esElRecomendado(id);
              final esSeleccionado = id == _metodoActual;

              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => _seleccionar(id),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LumiAppTheme.surface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: esSeleccionado
                                ? const Color(0xFFBD00FF)
                                : esRecomendado
                                    ? const Color(0xFFBD00FF)
                                        .withValues(alpha: 0.6)
                                    : LumiAppTheme.outline(context),
                            width: esSeleccionado || esRecomendado ? 2 : 1,
                          ),
                          boxShadow: esSeleccionado
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFBD00FF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF181433),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                metodo['icono'] as IconData,
                                color: metodo['colorIcono'] as Color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr(
                                      metodo['tituloEs'] as String,
                                      metodo['tituloEn'] as String,
                                    ),
                                    style: TextStyle(
                                      color: LumiAppTheme.primaryText(context),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF362C6B),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      tr(
                                        metodo['subtituloEs'] as String,
                                        metodo['subtituloEn'] as String,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tr(
                                      metodo['descripcionEs'] as String,
                                      metodo['descripcionEn'] as String,
                                    ),
                                    style: TextStyle(
                                      color: LumiAppTheme.secondaryText(context),
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (esRecomendado)
                      Positioned(
                        top: -12,
                        right: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBD00FF),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tr(
                                  'Recomendado por Lumi',
                                  'Recommended by Lumi',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}