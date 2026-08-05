import 'package:flutter/material.dart';
import '/services/api_service.dart';

class GuiaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> guiaData;

  const GuiaDetalleScreen({super.key, required this.guiaData});

  @override
  State<GuiaDetalleScreen> createState() => _GuiaDetalleScreenState();
}

class _GuiaDetalleScreenState extends State<GuiaDetalleScreen> {
  bool _isLoading = true;
  Map<String, dynamic> guiaActual = {};
  List<dynamic> subtareas = [];
  List<dynamic> consejos = [];
  List<dynamic> recursos = [];

  List<bool> tareasCompletadas = [];
  List<bool> cargando = [];

  @override
  void initState() {
    super.initState();
    _cargarDetallePlan();
  }

  Future<void> _cargarDetallePlan() async {
    final planId = widget.guiaData['id'] ?? widget.guiaData['plan_id'];
    
    if (planId != null) {
      final detalle = await ApiService.obtenerPlan(planId);
      if (detalle != null && mounted) {
        setState(() {
          guiaActual = detalle;
          subtareas = (detalle['subtareas'] as List?) ?? [];
          consejos = (detalle['consejos'] as List?) ?? [];
          recursos = (detalle['recursos'] as List?) ?? [];
          _actualizarListasEstado();
          _isLoading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        guiaActual = widget.guiaData;
        subtareas = (guiaActual['subtareas'] as List?) ?? [];
        consejos = (guiaActual['consejos'] as List?) ?? [];
        recursos = (guiaActual['recursos'] as List?) ?? [];
        _actualizarListasEstado();
        _isLoading = false;
      });
    }
  }

  void _actualizarListasEstado() {
    tareasCompletadas = List.generate(
      subtareas.length,
      (index) {
        final sub = subtareas[index];
        if (sub is Map && sub.containsKey('completada')) {
          return sub['completada'] == true;
        }
        return false;
      },
    );
    cargando = List.generate(subtareas.length, (_) => false);
  }

  void _mostrarModalModificarTarea(int? index) {
    final isSubtarea = index != null;
    
    // Safe string fallbacks to avoid null indexing errors
    final defaultTitle = isSubtarea 
        ? (subtareas[index]?['titulo'] ?? '') 
        : (guiaActual['nombre'] ?? guiaActual['titulo'] ?? '');
        
    final defaultDesc = isSubtarea 
        ? (subtareas[index]?['descripcion'] ?? '') 
        : (guiaActual['justificacion'] ?? '');

    final tituloController = TextEditingController(text: defaultTitle);
    final descController = TextEditingController(text: defaultDesc);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16003A),
        title: Text(
          isSubtarea ? 'Modificar Subtarea' : 'Modificar Plan General',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Título',
                labelStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF44AA))),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción / Instrucción',
                labelStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF44AA))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF44AA)),
            onPressed: () {
              setState(() {
                if (isSubtarea && subtareas[index] is Map) {
                  subtareas[index]['titulo'] = tituloController.text;
                  subtareas[index]['descripcion'] = descController.text;
                } else {
                  guiaActual['nombre'] = tituloController.text;
                  guiaActual['justificacion'] = descController.text;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Modificación aplicada al plan')),
              );
            },
            child: const Text('Actualizar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarTarea(int index) async {
    if (index >= subtareas.length || subtareas[index] is! Map) return;
    
    final sub = subtareas[index];
    final tareaId = sub['id'];

    if (tareaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La tarea no tiene id de base de datos.')),
      );
      return;
    }

    setState(() => cargando[index] = true);

    final ok = await ApiService.completarTarea(
      tareaId: tareaId,
      completada: true,
    );

    if (!mounted) return;

    if (!ok) {
      setState(() => cargando[index] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la tarea')),
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF44AA)),
            onPressed: () => _mostrarModalModificarTarea(null),
            tooltip: 'Modificar Plan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF44AA)))
          : SingleChildScrollView(
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
                          guiaActual['metodo_estudio'] ?? 'Método de estudio',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          guiaActual['justificacion'] ?? 'Sin descripción general',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Tiempo estimado total: ${guiaActual['tiempo_estimado_total'] ?? 0} minutos",
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
                    if (sub is! Map) return const SizedBox.shrink();

                    final isCargando = index < cargando.length ? cargando[index] : false;
                    final isCompletada = index < tareasCompletadas.length ? tareasCompletadas[index] : false;

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
                              isCargando
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      isCompletada
                                          ? Icons.check_circle_outline
                                          : Icons.radio_button_unchecked,
                                      color: isCompletada
                                          ? Colors.greenAccent
                                          : const Color(0xFFFF44AA),
                                    ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  sub['titulo'] ?? 'Subtarea',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white38, size: 18),
                                onPressed: () => _mostrarModalModificarTarea(index),
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
                            "Duración: ${sub['duracion_minutos'] ?? 0} min",
                            style: const TextStyle(
                              color: Color(0xFFFF44AA),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Prioridad: ${sub['prioridad'] ?? 'MEDIA'}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 15),
                          if (!isCompletada) ...[
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
                                child: const Text('Confirmar tarea completada', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              child: const Text(
                                'Tarea completada',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
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
                            if (r is! Map) return const SizedBox.shrink();
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
                ],
              ),
            ),
    );
  }
}