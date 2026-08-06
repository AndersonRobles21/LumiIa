import 'package:flutter/material.dart';
import 'package:frontend/screens/app_language.dart';
import '../services/api_service.dart';

class GuiaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> guiaData;

  const GuiaDetalleScreen({super.key, required this.guiaData});

  @override
  State<GuiaDetalleScreen> createState() => _GuiaDetalleScreenState();
}

class _GuiaDetalleScreenState extends State<GuiaDetalleScreen>
    with AppLanguageListenerMixin<GuiaDetalleScreen> {
  late List<dynamic> subtareas;
  late List<dynamic> consejos;
  late List<dynamic> recursos;

  late List<bool> tareasCompletadas;
  late List<bool> cargando;

  @override
  void initState() {
    super.initState();

    subtareas = widget.guiaData['subtareas'] as List? ?? [];
    consejos = widget.guiaData['consejos'] as List? ?? [];
    recursos = widget.guiaData['recursos'] as List? ?? [];

    tareasCompletadas = List.generate(
      subtareas.length,
      (index) => subtareas[index]['completada'] ?? false,
    );

    cargando = List.generate(subtareas.length, (_) => false);
  }

  Future<void> _confirmarTarea(int index) async {
    final sub = subtareas[index];
    final tareaId = sub['id'];

    if (tareaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('La tarea no tiene id.', 'The task has no id.')),
        ),
      );
      return;
    }

    setState(() {
      cargando[index] = true;
    });

    final ok = await ApiService.completarTarea(
      tareaId: tareaId,
      completada: true,
    );

    if (!mounted) return;

    if (!ok) {
      setState(() {
        cargando[index] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('No se pudo actualizar la tarea', 'Could not update the task')),
        ),
      );
      return;
    }

    setState(() {
      tareasCompletadas[index] = true;
      cargando[index] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'TU PLAN DE ESTUDIO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16003A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.guiaData['metodo_estudio'] ?? tr('Método de estudio', 'Study method'),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.guiaData['justificacion'] ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "${tr('Tiempo estimado', 'Estimated time')}: ${widget.guiaData['tiempo_estimado_total'] ?? 0} ${tr('minutos', 'minutes')}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ...List.generate(subtareas.length, (index) {
              final sub = subtareas[index];
              

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1A3A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF44AA).withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cargando[index]
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                tareasCompletadas[index]
                                    ? Icons.check_circle_outline
                                    : Icons.radio_button_unchecked,
                                color: tareasCompletadas[index]
                                    ? const Color(0xFF2E1B4E)
                                    : const Color(0xFFFF44AA),
                              ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            sub['titulo'] ?? '',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      sub['descripcion'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${tr('Duración', 'Duration')}: ${sub['duracion_minutos']} ${tr('min', 'min')}",
                      style: const TextStyle(
                        color: Color(0xFFFF44AA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "${tr('Prioridad', 'Priority')}: ${sub['prioridad']}",
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 10),

                    if (!tareasCompletadas[index]) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF44AA),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _confirmarTarea(index),
                          child: Text(tr('Confirmar tarea completada', 'Confirm task completed')),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E1B4E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tr('Tarea completada', 'Task completed'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            if (consejos.isNotEmpty) ...[
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16003A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Consejos",
                      style: TextStyle(
                        color: Color(0xFFFF44AA),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...consejos.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          "• $c",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (recursos.isNotEmpty) ...[
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16003A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recursos recomendados",
                      style: TextStyle(
                        color: Color(0xFFFF44AA),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...recursos.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['nombre'] ?? '',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              r['descripcion'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16003A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.guiaData['resumen_final'] ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
