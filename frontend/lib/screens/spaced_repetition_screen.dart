import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_language.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  final String tituloTarea;
  final List<String> conceptos;

  const SpacedRepetitionScreen({
    super.key,
    required this.tituloTarea,
    this.conceptos = const [],
  });

  @override
  State<SpacedRepetitionScreen> createState() =>
      _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen>
    with AppLanguageListenerMixin<SpacedRepetitionScreen> {
  int _conceptoActualIndex = 0;

  List<String> get _listaConceptos {
    if (widget.conceptos.isNotEmpty) {
      return widget.conceptos;
    }

    return [widget.tituloTarea];
  }

  void _siguienteConcepto() {
    if (_conceptoActualIndex < _listaConceptos.length - 1) {
      setState(() => _conceptoActualIndex++);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            '🎉 ¡Has completado todos los repasos programados para hoy!',
            '🎉 You have completed all of today’s scheduled reviews!',
          ),
        ),
        backgroundColor: const Color(0xFFBD00FF),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalConceptos = _listaConceptos.length;
    final conceptoActual = _listaConceptos[_conceptoActualIndex];

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: LumiAppTheme.primaryText(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('Repetición espaciada', 'Spaced repetition'),
          style: TextStyle(
            color: LumiAppTheme.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: Responsive.tamanioTitulo(context),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.paddingHorizontalRecomendado(context),
          vertical: Responsive.espacio(context),
        ),
        child: Column(
          children: [
            Image.asset(
              'logo/spaced_repetition.png',
              width: double.infinity,
              height: Responsive.altoPantalla(context) * 0.12,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Container(
                  padding: EdgeInsets.all(Responsive.espacio(context)),
                  decoration: BoxDecoration(
                    color: LumiAppTheme.surface(context),
                    borderRadius: BorderRadius.circular(
                      Responsive.radioBorde(context),
                    ),
                  ),
                  child: Text(
                    tr(
                      '✨ ¡Repasa para fortalecer tu memoria! Lumi te mostrará '
                      'los conceptos en el momento ideal.',
                      '✨ Review to strengthen your memory! Lumi will show you '
                      'concepts at the ideal time.',
                    ),
                    style: TextStyle(
                      color: LumiAppTheme.secondaryText(context),
                      fontSize: Responsive.tamanioTexto(context),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: Responsive.espacio(context)),
            Container(
              padding: EdgeInsets.all(Responsive.espacio(context) * 1.5),
              decoration: BoxDecoration(
                color: LumiAppTheme.surface(context),
                borderRadius: BorderRadius.circular(
                  Responsive.radioBorde(context),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    color: LumiAppTheme.secondaryText(context),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Repaso activo', 'Active review'),
                          style: TextStyle(
                            color: LumiAppTheme.primaryText(context),
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.tamanioSubtitulo(context),
                          ),
                        ),
                        Text(
                          tr(
                            'Tienes $totalConceptos conceptos clave para repasar.',
                            'You have $totalConceptos key concepts to review.',
                          ),
                          style: TextStyle(
                            color: LumiAppTheme.secondaryText(context),
                            fontSize: Responsive.tamanioTexto(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.espacio(context) * 2),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.espacio(context) * 2),
                decoration: BoxDecoration(
                  color: LumiAppTheme.surface(context),
                  borderRadius: BorderRadius.circular(
                    Responsive.radioBorde(context),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb,
                                color: Colors.amber,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('Concepto clave', 'Key concept'),
                                style: TextStyle(
                                  color: LumiAppTheme.primaryText(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_conceptoActualIndex + 1}/$totalConceptos',
                            style: TextStyle(
                              color: LumiAppTheme.secondaryText(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.espacio(context) * 2),
                      Text(
                        conceptoActual,
                        style: TextStyle(
                          color: const Color(0xFF00F0FF),
                          fontSize: Responsive.tamanioTitulo(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: Responsive.espacio(context)),
                      Text(
                        tr(
                          'Reflexiona sobre este concepto vinculado a tu tarea '
                          '"${widget.tituloTarea}". ¿Cómo lo explicarías o lo '
                          'aplicarías en el desarrollo?',
                          'Think about this concept related to your task '
                          '"${widget.tituloTarea}". How would you explain or '
                          'apply it?',
                        ),
                        style: TextStyle(
                          color: LumiAppTheme.secondaryText(context),
                          fontSize: Responsive.tamanioTexto(context),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.espacio(context) * 2),
            Text(
              tr(
                '¿Qué tan difícil es recordarlo?',
                'How difficult is it to remember?',
              ),
              style: TextStyle(
                color: LumiAppTheme.secondaryText(context),
                fontSize: Responsive.tamanioTexto(context),
              ),
            ),
            SizedBox(height: Responsive.espacio(context)),
            Row(
              children: [
                Expanded(
                  child: _buildBotonDificultad(
                    texto: tr('Difícil', 'Hard'),
                    color: Colors.redAccent,
                    icono: Icons.sentiment_very_dissatisfied,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBotonDificultad(
                    texto: tr('Regular', 'Medium'),
                    color: Colors.amber,
                    icono: Icons.sentiment_neutral,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBotonDificultad(
                    texto: tr('Fácil', 'Easy'),
                    color: Colors.greenAccent,
                    icono: Icons.sentiment_satisfied,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.espacio(context) * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonDificultad({
    required String texto,
    required Color color,
    required IconData icono,
  }) {
    return InkWell(
      onTap: _siguienteConcepto,
      borderRadius: BorderRadius.circular(
        Responsive.radioBorde(context),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Responsive.espacio(context) * 1.5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1B163B),
          borderRadius: BorderRadius.circular(
            Responsive.radioBorde(context),
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: color,
              size: Responsive.tamanioSubtitulo(context),
            ),
            SizedBox(height: Responsive.espacio(context) / 2),
            Text(
              texto,
              style: TextStyle(
                color: color,
                fontSize: Responsive.tamanioTexto(context) - 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}