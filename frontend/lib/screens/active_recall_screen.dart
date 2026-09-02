import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ActiveRecallScreen extends StatefulWidget {
  final String tituloTarea;
  final List<Map<String, dynamic>> preguntasRespuestas;

  const ActiveRecallScreen({
    super.key,
    required this.tituloTarea,
    this.preguntasRespuestas = const [],
  });

  @override
  State<ActiveRecallScreen> createState() => _ActiveRecallScreenState();
}

class _ActiveRecallScreenState extends State<ActiveRecallScreen> {
  bool _mostrarRespuesta = false;
  int _preguntaActualIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Definir la lista de preguntas a usar (dinámica o de respaldo)
    final listaPreguntas = widget.preguntasRespuestas.isNotEmpty
        ? widget.preguntasRespuestas
        : [
            {
              'pregunta': '¿Qué es y para qué sirve ${widget.tituloTarea}?',
              'respuesta':
                  'Es el concepto principal estructurado en tu plan de estudio de Lumi para lograr el máximo aprendizaje y dominio del tema.',
            }
          ];

    final totalPreguntas = listaPreguntas.length;
    final itemActual = listaPreguntas[_preguntaActualIndex];
    final textoPregunta = itemActual['pregunta'] ?? itemActual['titulo'] ?? 'Pregunta de repaso';
    final textoRespuesta = itemActual['respuesta'] ?? itemActual['descripcion'] ?? 'Respuesta detallada no disponible.';

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
          'Active Recall',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Mascota con bocadillo informativo
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: Responsive.esMovil(context) ? 90 : 130,
              ),
              child: Image.asset(
                'logo/active_recall.png',
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF1B163B), borderRadius: BorderRadius.circular(15)),
                  child: const Text('✨ ¡Pon a prueba tu memoria! Intenta recordar sin mirar tus apuntes.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Piensa la respuesta y presiona el botón\npara comprobar',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Tarjeta de la Pregunta Dinámica
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B163B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF3B2F6E).withOpacity(0.5)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        '${_preguntaActualIndex + 1}/$totalPreguntas',
                        style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              textoPregunta,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            if (_mostrarRespuesta) ...[
                              const SizedBox(height: 20),
                              const Divider(color: Color(0xFFBD00FF)),
                              const SizedBox(height: 20),
                              Text(
                                textoRespuesta,
                                style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 14, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón de Comprobar / Siguiente
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (!_mostrarRespuesta) {
                      _mostrarRespuesta = true;
                    } else {
                      _mostrarRespuesta = false;
                      if (_preguntaActualIndex < totalPreguntas - 1) {
                        _preguntaActualIndex++;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 ¡Has completado todas las preguntas de Active Recall!'),
                            backgroundColor: Color(0xFFBD00FF),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF44AA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text(
                  _mostrarRespuesta ? 'Siguiente' : 'Respuesta',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}