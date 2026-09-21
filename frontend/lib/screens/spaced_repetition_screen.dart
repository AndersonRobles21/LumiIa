import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  final String tituloTarea;
  final List<String> conceptos;

  const SpacedRepetitionScreen({
    super.key,
    required this.tituloTarea,
    this.conceptos = const [],
  });

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> {
  int _conceptoActualIndex = 0;

  void _siguienteConcepto(String dificultad) {
    final listaConceptos = widget.conceptos.isNotEmpty
        ? widget.conceptos
        : [widget.tituloTarea];

    if (_conceptoActualIndex < listaConceptos.length - 1) {
      setState(() => _conceptoActualIndex++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Has completado todos los repasos programados para hoy!'),
          backgroundColor: Color(0xFFBD00FF),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaConceptos = widget.conceptos.isNotEmpty
        ? widget.conceptos
        : [widget.tituloTarea];

    final totalConceptos = listaConceptos.length;
    final conceptoActual = listaConceptos[_conceptoActualIndex];

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: LumiAppTheme.primaryText(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Repetición Espaciada',
          style: TextStyle(color: LumiAppTheme.primaryText(context), fontWeight: FontWeight.bold, fontSize: Responsive.tamanioTitulo(context)),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: Responsive.espacio(context)),
        child: Column(
          children: [
            // Mascota con Banner
            Image.asset(
              'logo/spaced_repetition.png',
              width: double.infinity,
              height: Responsive.altoPantalla(context) * 0.12,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                padding: EdgeInsets.all(Responsive.espacio(context)),
                decoration: BoxDecoration(color: LumiAppTheme.surface(context), borderRadius: BorderRadius.circular(Responsive.radioBorde(context))),
                child: Text('✨ ¡Repasa para tu memoria! Lumi te mostrará los conceptos en el momento ideal.', style: TextStyle(color: LumiAppTheme.secondaryText(context), fontSize: Responsive.tamanioTexto(context))),
              ),
            ),
            SizedBox(height: Responsive.espacio(context)),

            // Banner del Repaso de hoy
            Container(
              padding: EdgeInsets.all(Responsive.espacio(context) * 1.5),
              decoration: BoxDecoration(
                color: LumiAppTheme.surface(context),
                borderRadius: BorderRadius.circular(Responsive.radioBorde(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_outlined, color: LumiAppTheme.secondaryText(context), size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Repaso Activo', style: TextStyle(color: LumiAppTheme.primaryText(context), fontWeight: FontWeight.bold, fontSize: Responsive.tamanioSubtitulo(context))),
                      Text('Tienes $totalConceptos conceptos clave para repasar.', style: TextStyle(color: LumiAppTheme.secondaryText(context), fontSize: Responsive.tamanioTexto(context))),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.espacio(context) * 2),

            // Tarjeta explicativa del concepto dinámico
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.espacio(context) * 2),
                decoration: BoxDecoration(
                  color: LumiAppTheme.surface(context),
                  borderRadius: BorderRadius.circular(Responsive.radioBorde(context)),
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
                              const Icon(Icons.lightbulb, color: Colors.amber, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Concepto clave',
                                style: TextStyle(color: LumiAppTheme.primaryText(context), fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text('${_conceptoActualIndex + 1}/$totalConceptos', style: TextStyle(color: LumiAppTheme.secondaryText(context), fontSize: 12)),
                        ],
                      ),
                      SizedBox(height: Responsive.espacio(context) * 2),
                      Text(
                        conceptoActual,
                        style: TextStyle(color: const Color(0xFF00F0FF), fontSize: Responsive.tamanioTitulo(context), fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: Responsive.espacio(context)),
                      Text(
                        'Reflexiona sobre este concepto vinculado a tu tarea "${widget.tituloTarea}". ¿Cómo lo explicarías o aplicarías en el desarrollo?',
                        style: TextStyle(color: LumiAppTheme.secondaryText(context), fontSize: Responsive.tamanioTexto(context), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.espacio(context) * 2),

            // Opciones de Dificultad para avanzar
            Text('¿Qué tan difícil es recordarlo?', style: TextStyle(color: Colors.white70, fontSize: Responsive.tamanioTexto(context))),
            SizedBox(height: Responsive.espacio(context)),
            Row(
              children: [
                Expanded(child: _buildBotonDificultad('Difícil', Colors.redAccent, Icons.sentiment_very_dissatisfied)),
                const SizedBox(width: 8),
                Expanded(child: _buildBotonDificultad('Regular', Colors.amber, Icons.sentiment_neutral)),
                const SizedBox(width: 8),
                Expanded(child: _buildBotonDificultad('Fácil', Colors.greenAccent, Icons.sentiment_satisfied)),
              ],
            ),
            SizedBox(height: Responsive.espacio(context) * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonDificultad(String texto, Color color, IconData icono) {
    return InkWell(
      onTap: () => _siguienteConcepto(texto),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: Responsive.espacio(context) * 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFF1B163B),
          borderRadius: BorderRadius.circular(Responsive.radioBorde(context)),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: Responsive.tamanioSubtitulo(context)),
            SizedBox(height: Responsive.espacio(context) / 2),
            Text(texto, style: TextStyle(color: color, fontSize: Responsive.tamanioTexto(context) - 2, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}