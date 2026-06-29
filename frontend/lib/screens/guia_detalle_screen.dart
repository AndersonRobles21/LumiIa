import 'package:flutter/material.dart';

class GuiaDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> guiaData;

  const GuiaDetalleScreen({super.key, required this.guiaData});

  @override
  Widget build(BuildContext context) {
    // Extraemos la lista de actividades del JSON que viene de la IA
    final actividades = guiaData['actividades'] as List? ?? [];
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('TU PLAN DE ESTUDIO', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Resumen de la IA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF16003A), borderRadius: BorderRadius.circular(20)),
              child: Text(
                guiaData['justificacion_metodo'] ?? 'Tu plan personalizado',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),

            // Lista de actividades
            ...actividades.map((act) => Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1A3A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF44AA).withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(act['titulo'], style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(act['descripcion'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 10),
                  const Text('✅ Micro-tareas:', style: TextStyle(color: Color(0xFFFF44AA), fontWeight: FontWeight.bold)),
                  ...((act['tareas_checklist'] as List? ?? []).map((tarea) => Text('• $tarea', style: const TextStyle(color: Colors.white70)))),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}