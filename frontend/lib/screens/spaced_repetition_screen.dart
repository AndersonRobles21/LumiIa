import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Repetición Espaciada',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Mascota con Banner
            Image.asset(
              'logo/spaced_repetition.png',
              width: double.infinity,
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1B163B), borderRadius: BorderRadius.circular(15)),
                child: const Text('✨ ¡Repasa para tu memoria! Lumi te mostrará los conceptos en el momento ideal.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 12),

            // Banner del Repaso de hoy
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B163B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: Colors.white70, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Repaso Activo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Tienes $totalConceptos conceptos clave para repasar.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta explicativa del concepto dinámico
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B163B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lightbulb, color: Colors.amber, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Concepto clave',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text('${_conceptoActualIndex + 1}/$totalConceptos', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        conceptoActual,
                        style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reflexiona sobre este concepto vinculado a tu tarea "${widget.tituloTarea}". ¿Cómo lo explicarías o aplicarías en el desarrollo?',
                        style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opciones de Dificultad para avanzar
            const Text('¿Qué tan difícil es recordarlo?', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildBotonDificultad('Difícil', Colors.redAccent, Icons.sentiment_very_dissatisfied)),
                const SizedBox(width: 8),
                Expanded(child: _buildBotonDificultad('Regular', Colors.amber, Icons.sentiment_neutral)),
                const SizedBox(width: 8),
                Expanded(child: _buildBotonDificultad('Fácil', Colors.greenAccent, Icons.sentiment_satisfied)),
              ],
            ),
            const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B163B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(height: 4),
            Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}