import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/services/api_service.dart';
import 'seleccionar_metodo_screen.dart';
import 'pomodoro_screen.dart';
import 'feynman_screen.dart';
import 'active_recall_screen.dart';
import 'spaced_repetition_screen.dart';

class GuiaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> guiaData;
  final String? userId;

  const GuiaDetalleScreen({
    super.key,
    required this.guiaData,
    this.userId,
  });

  @override
  State<GuiaDetalleScreen> createState() => _GuiaDetalleScreenState();
}

class _GuiaDetalleScreenState extends State<GuiaDetalleScreen> {
  bool _isLoading = true;
  Map<String, dynamic> guiaActual = {};
  List<dynamic> fasesPasos = [];
  List<dynamic> consejos = [];
  List<dynamic> recursos = [];
  List<dynamic> conceptosClave = [];
  List<dynamic> preguntasRecall = [];

  int _faseActualIndex = 0;
  List<bool> cargandoFases = [];

  final Map<int, int> _nivelesExplicacionFase = {};
  int _nivelExplicacionGeneral = 0;

  final List<Map<String, dynamic>> _mensajes = [];

  String formatearTiempo(int minutos) {
    final horas = minutos ~/ 60;
    final minutosRestantes = minutos % 60;
    if (horas == 0) return "$minutosRestantes min";
    if (minutosRestantes == 0) return "$horas h";
    return "$horas h $minutosRestantes min";
  }

  Future<void> _abrirUrl(String urlString) async {
    if (urlString.trim().isEmpty) return;
    final Uri uri = Uri.parse(urlString.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDetallePlan();
  }

  Future<void> _cargarDetallePlan() async {
    final planId = widget.guiaData['id'] ?? widget.guiaData['plan_id'];

    if (planId != null) {
      final detalle = await ApiService.obtenerPlan(planId.toString());
      if (detalle != null && mounted) {
        setState(() {
          guiaActual = detalle;
          subtareas = (detalle['subtareas'] as List?) ?? [];
          consejos = (detalle['consejos'] as List?) ?? [];
          recursos = (detalle['recursos'] as List?) ?? [];
        });
        _sincronizarSubtareasDesdeBackend();
        _isLoading = false;
        return;
      }
    }

    if (mounted) {
      setState(() {
        guiaActual = widget.guiaData;
        subtareas = (guiaActual['subtareas'] as List?) ?? [];
        consejos = (guiaActual['consejos'] as List?) ?? [];
        recursos = (guiaActual['recursos'] as List?) ?? [];
      });
      _sincronizarSubtareasDesdeBackend();
      _isLoading = false;
    }
  }

  Future<void> _sincronizarSubtareasDesdeBackend() async {
    final userId = (widget.userId ?? guiaActual['usuario_id'] ?? widget.guiaData['usuario_id'] ?? widget.guiaData['user_id'] ?? '').toString();
    if (userId.isEmpty) {
      _actualizarListasEstado();
      return;
    }

    final tareas = await ApiService.getPlanesEstudio(userId) ?? const [];
    final mapaTitulos = <String, Map<String, dynamic>>{};

    for (final tarea in tareas) {
      if (tarea is Map) {
        final tareaMap = Map<String, dynamic>.from(tarea);
        final nombre = (tareaMap['nombre'] ?? tareaMap['titulo'] ?? '').toString();
        if (nombre.isNotEmpty) mapaTitulos[nombre.toLowerCase()] = tareaMap;
      }
    }

    for (int i = 0; i < subtareas.length; i++) {
      final sub = subtareas[i];
      if (sub is! Map) continue;
      final titulo = (sub['titulo'] ?? sub['nombre'] ?? '').toString();
      final tareaServidor = mapaTitulos[titulo.toLowerCase()];

      if (tareaServidor != null) {
        sub['id'] = tareaServidor['id'] ?? sub['id'];
        sub['completada'] = tareaServidor['completada'] == true || (tareaServidor['estado'] ?? '').toString().toUpperCase() == 'COMPLETADA';
      }
    }

    _actualizarListasEstado();
  }

  void _actualizarListasEstado() {
    tareasCompletadas = List.generate(
      subtareas.length,
      (index) {
        final sub = subtareas[index];
        if (sub is Map && sub.containsKey('completada')) {
          return sub['completada'] == true;
        }
      }
    }

    if (!hayFasesPendientes && fasesPasos.isNotEmpty) {
      _faseActualIndex = fasesPasos.length - 1;
      _mensajes.add({
        'esBot': true,
        'texto':
            '🏆 ¡Increíble! Has finalizado por completo todos los pasos de esta guía.',
      });
    }
  }

  // 🔄 REINICIO TOTAL DEL PROGRESO
  Future<void> _reiniciarProgreso() async {
    final planId = (guiaActual['id'] ?? guiaActual['plan_id'])?.toString();

    for (var fase in fasesPasos) {
      if (fase is Map) {
        fase['completado'] = false;
        final subpasos = (fase['subpasos'] as List?) ?? [];
        for (var sub in subpasos) {
          if (sub is Map) sub['completado'] = false;
        }
      }
    }

    if (planId != null) {
      await ApiService.actualizarProgresoPlan(
        planId: planId,
        pasos: fasesPasos,
      );
    }

    setState(() {
      _faseActualIndex = 0;
      _inicializarMensajesChat();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 ¡Progreso reiniciado! Volviste al Paso 1.'),
          backgroundColor: Color(0xFF00F0FF),
        ),
      );
    }
  }

  Future<void> _confirmarTarea(int index) async {
    if (index >= subtareas.length || subtareas[index] is! Map) return;

    final sub = subtareas[index];
    final tareaId = sub['id'];

    if (tareaId == null) {
      final userId = (widget.userId ?? guiaActual['usuario_id'] ?? widget.guiaData['usuario_id'] ?? widget.guiaData['user_id'] ?? '').toString();
      if (userId.isNotEmpty) {
        final tareas = await ApiService.getPlanesEstudio(userId) ?? const [];
        for (final tarea in tareas) {
          if (tarea is Map) {
            final nombre = (tarea['nombre'] ?? tarea['titulo'] ?? '').toString();
            final tituloActual = (sub['titulo'] ?? sub['nombre'] ?? '').toString();
            if (nombre.toLowerCase() == tituloActual.toLowerCase()) {
              sub['id'] = tarea['id'];
              break;
            }
          }
        }
      }

      if (sub['id'] == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La tarea no tiene id de base de datos.')),
        );
        return;
      }
    }

    setState(() {});
  }

    final ok = await ApiService.completarTarea(
      tareaId: sub['id'].toString(),
      completada: true,
    );

    final fase = fasesPasos[faseIndex];
    final subpasosList = (fase['subpasos'] as List?) ?? [];

    bool faltanSubpasos = subpasosList.any((sub) => sub['completado'] != true);
    if (faltanSubpasos && subpasosList.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Debes marcar todos los subpasos de esta fase antes de continuar.',
          ),
          backgroundColor: Color(0xFFFF44AA),
        ),
      );
      return;
    }

    final userId = (widget.userId ?? guiaActual['usuario_id'] ?? widget.guiaData['usuario_id'] ?? widget.guiaData['user_id'] ?? '').toString();
    if (userId.isNotEmpty) {
      await ApiService.syncTaskStats(userId);
    }

    setState(() {
      sub['completada'] = true;
      tareasCompletadas[index] = true;
      cargando[index] = false;
    });
  }

  void _abrirPantallaTecnicaDinamica() {
    final metodo = (guiaActual['metodo_estudio'] ?? 'Pomodoro')
        .toString()
        .toLowerCase();
    final titulo = (guiaActual['nombre'] ?? guiaActual['titulo'] ?? 'Trabajo')
        .toString();
    final conceptosIA = List<String>.from(
      conceptosClave.map((e) => e.toString()),
    );
    final preguntasIA = List<Map<String, dynamic>>.from(
      preguntasRecall.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
    );

    if (metodo.contains('feynman')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FeynmanScreen(
            tituloTarea: titulo,
            conceptos: conceptosIA.isNotEmpty ? conceptosIA : [titulo],
          ),
        ),
      );
    } else if (metodo.contains('active')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveRecallScreen(
            tituloTarea: titulo,
            preguntasRespuestas: preguntasIA,
          ),
        ),
      );
    } else if (metodo.contains('spaced') || metodo.contains('repetic')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpacedRepetitionScreen(
            tituloTarea: titulo,
            conceptos: conceptosIA.isNotEmpty ? conceptosIA : [titulo],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PomodoroScreen(tituloTarea: titulo)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tituloPrincipal = (guiaActual['nombre'] ?? guiaActual['titulo'] ?? widget.guiaData['nombre'] ?? widget.guiaData['titulo'] ?? 'Plan de estudio').toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          tituloPrincipal,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // 🔄 BOTÓN DE REINICIAR PROGRESO
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F0FF), size: 22),
            tooltip: 'Reiniciar pasos',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1736),
                  title: const Text(
                    '¿Reiniciar progreso?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Esto desmarcará todos tus checkboxes y te devolverá al Paso 1. ¿Deseas continuar?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Color(0xFF9E9AC8)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF44AA),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _reiniciarProgreso();
                      },
                      child: const Text(
                        'Sí, reiniciar',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // ⚡ BOTÓN DE MÉTODO DINÁMICO
          IconButton(
            icon: const Icon(
              Icons.flash_on,
              color: Colors.amberAccent,
              size: 24,
            ),
            onPressed: _abrirPantallaTecnicaDinamica,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: const Color(0xFF13102A),
                  child: const Text(
                    'Consejo: Toca 🔄 arriba para reiniciar tus pasos o ⚡ para abrir tu técnica de estudio.',
                    style: TextStyle(
                      color: Color(0xFF9E9AC8),
                      fontSize: 11,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Lista del Chat
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final msg = _mensajes[index];
                      final esBot = msg['esBot'] as bool;
                      final esBienvenida = msg['tipo'] == 'bienvenida';
                      final faseIndexChat = msg['faseIndexChat'];
                      final listaRecursosMsg =
                          (msg['listaRecursos'] as List?) ?? [];

                      List<dynamic> subpasosDeEstaFase = [];
                      bool faseCompletadaEstado = false;
                      bool faseCargandoEstado = false;

                      if (faseIndexChat != null &&
                          faseIndexChat < fasesPasos.length) {
                        final faseObj = fasesPasos[faseIndexChat];
                        subpasosDeEstaFase =
                            (faseObj['subpasos'] as List?) ?? [];
                        faseCompletadaEstado = faseObj['completado'] == true;
                        faseCargandoEstado = cargandoFases[faseIndexChat];
                      }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1A3A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF44AA).withValues(alpha: 0.5),
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
                            Flexible(
                              child: Column(
                                crossAxisAlignment: esBot
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: esBot
                                          ? const Color(0xFF1A1736)
                                          : const Color(0xFF32285E),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: esBot
                                            ? const Color(
                                                0xFF4A3E8D,
                                              ).withOpacity(0.4)
                                            : const Color(0xFFBD00FF),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg['texto'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            height: 1.4,
                                          ),
                                        ),

                                        // 🔗 Enlaces recomendados
                                        if (listaRecursosMsg.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          ...listaRecursosMsg.map((rec) {
                                            final nombreRec =
                                                rec['nombre'] ??
                                                rec['titulo'] ??
                                                'Enlace de apoyo';
                                            final urlRec = rec['url'] ?? '';
                                            if (urlRec.isEmpty)
                                              return const SizedBox.shrink();

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: InkWell(
                                                onTap: () => _abrirUrl(urlRec),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF00F0FF,
                                                    ).withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF00F0FF,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.link,
                                                        color: Color(
                                                          0xFF00F0FF,
                                                        ),
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          'Abrir: $nombreRec 🚀',
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF00F0FF,
                                                                ),
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],

                                        // 🟩 CHECKLIST DE SUBPASOS DE ESTA FASE
                                        if (subpasosDeEstaFase.isNotEmpty &&
                                            faseIndexChat != null) ...[
                                          const SizedBox(height: 12),
                                          const Divider(
                                            color: Color(0xFF4A3E8D),
                                            height: 1,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            '📌 Subpasos obligatorios para este paso:',
                                            style: TextStyle(
                                              color: Color(0xFF00F0FF),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ...List.generate(
                                            subpasosDeEstaFase.length,
                                            (sIdx) {
                                              final subMap =
                                                  subpasosDeEstaFase[sIdx];
                                              bool subCompletado =
                                                  subMap['completado'] == true;
                                              return CheckboxListTile(
                                                contentPadding: EdgeInsets.zero,
                                                dense: true,
                                                title: Text(
                                                  subMap['texto'] ?? '',
                                                  style: TextStyle(
                                                    color: subCompletado
                                                        ? Colors.white38
                                                        : Colors.white,
                                                    fontSize: 11.5,
                                                    decoration: subCompletado
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                value: subCompletado,
                                                activeColor: const Color(
                                                  0xFFFF44AA,
                                                ),
                                                checkColor: Colors.black,
                                                onChanged: faseCompletadaEstado
                                                    ? null
                                                    : (bool? val) {
                                                        _actualizarSubpasoFase(
                                                          faseIndexChat,
                                                          sIdx,
                                                          val,
                                                        );
                                                      },
                                              );
                                            },
                                          ),
                                        ],

                                        // 🔘 BOTONES DE LA FASE (Explicar y Completar)
                                        if (faseIndexChat != null &&
                                            !faseCompletadaEstado) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFF00F0FF,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFF00F0FF),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                ),
                                                onPressed: () => _explicarFase(
                                                  faseIndexChat,
                                                ),
                                                icon: const Icon(
                                                  Icons.help_outline,
                                                  size: 14,
                                                ),
                                                label: Text(
                                                  'Explicar Paso ${faseIndexChat + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              faseCargandoEstado
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                              0xFFFF44AA,
                                                            ),
                                                          ),
                                                    )
                                                  : ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFFF44AA,
                                                            ),
                                                        foregroundColor:
                                                            Colors.black,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                      ),
                                                      onPressed: () =>
                                                          _completarFasePaso(
                                                            faseIndexChat,
                                                          ),
                                                      icon: const Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        size: 14,
                                                      ),
                                                      label: Text(
                                                        'Completar Paso ${faseIndexChat + 1}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Botón para cambiar método de estudio en bienvenida
                                  // Botón para cambiar método de estudio en bienvenida
                                  if (esBienvenida) ...[
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () async {
                                        // 1. Abrimos la pantalla para seleccionar el nuevo método usando el que la IA asignó
                                        final nuevoMetodo = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SeleccionarMetodoScreen(
                                              tituloTarea: tituloPlan,
                                              metodoRecomendado:
                                                  guiaActual['metodo_estudio'],
                                              onMetodoSeleccionado: (metodo) {
                                                setState(() {
                                                  guiaActual['metodo_estudio'] =
                                                      metodo;
                                                });
                                              },
                                            ),
                                          ),
                                        );

                                        // 2. Si se seleccionó un método nuevo, actualizamos el backend, guardamos y regeneramos los pasos
                                        // 2. Si se seleccionó un método nuevo, actualizamos el backend, guardamos y regeneramos los pasos
                                        if (nuevoMetodo != null && mounted) {
                                          setState(() => _isLoading = true);

                                          final planId =
                                              (guiaActual['id'] ??
                                                      guiaActual['plan_id'])
                                                  ?.toString();
                                          final userIdRaw =
                                              guiaActual['usuario_id'] ??
                                              widget.guiaData['usuario_id'];
                                          print(
                                            "🔍 DEBUG USER_ID EN FLUTTER: $userIdRaw",
                                          ); // Para ver qué trae realmente

                                          final userId =
                                              userIdRaw?.toString() ?? '';

                                          if (userId.isEmpty || userId == '1') {
                                            print(
                                              "⚠️ CUIDADO: El ID de usuario está vacío o es '1'",
                                            );
                                          }

                                          if (planId != null) {
                                            final planRegenerado =
                                                await ApiService.regenerarPlanExistente(
                                                  planId: planId,
                                                  metodoEstudio: nuevoMetodo,
                                                  userId: userId,
                                                  titulo: tituloPlan,
                                                  descripcion:
                                                      guiaActual['descripcion'] ??
                                                      '',
                                                  fechaEntrega:
                                                      guiaActual['fecha_entrega'] ??
                                                      DateTime.now()
                                                          .add(
                                                            const Duration(
                                                              days: 3,
                                                            ),
                                                          )
                                                          .toIso8601String(),
                                                  dificultad:
                                                      guiaActual['dificultad'] ??
                                                      'Media',
                                                );

                                            if (planRegenerado != null &&
                                                mounted) {
                                              setState(() {
                                                // Reemplazamos la guía actual con el mapa que devolvió el backend (que ya trae los nuevos pasos del método)
                                                guiaActual =
                                                    Map<String, dynamic>.from(
                                                      planRegenerado,
                                                    );
                                                guiaActual['metodo_estudio'] =
                                                    nuevoMetodo;

                                                // Extraemos las nuevas listas y reiniciamos el chat con los pasos del nuevo método
                                                _extraerListasDetalle();
                                                _faseActualIndex =
                                                    0; // Volvemos al inicio del nuevo plan
                                                _inicializarMensajesChat();
                                                _isLoading = false;

                                                _mensajes.add({
                                                  'esBot': true,
                                                  'texto':
                                                      '🚀 ¡Listo! He cambiado tu plan al método **$nuevoMetodo**, regeneré tus pasos y se ha guardado en la base de datos.',
                                                });
                                              });

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '¡Cambiado a $nuevoMetodo y guardado con éxito! 🚀',
                                                  ),
                                                ),
                                              );
                                            } else {
                                              setState(
                                                () => _isLoading = false,
                                              );
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      '⚠️ Error al comunicarse con el servidor para actualizar el método.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          } else {
                                            setState(() => _isLoading = false);
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF261D4C),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFBD00FF),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.settings_suggest,
                                              color: Color(0xFF00F0FF),
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Cambiar método de estudio',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            CircleAvatar(
                                              radius: 10,
                                              backgroundColor: Color(
                                                0xFFBD00FF,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!esBot) ...[
                              const SizedBox(width: 8),
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF2E7D32),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Botones inferiores predeterminados
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF0D0B1E),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildBotonPredeterminado("Paso a Paso"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBotonPredeterminado(
                              "Explica que toca hacer",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBotonPredeterminado(
                              "¿Qué es este tema?",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBotonPredeterminado("Dame un consejo"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAvatarLumi({required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1F1A3A),
      child: ClipOval(
        child: Image.asset(
          'logo/chat_ia.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.smart_toy,
              color: const Color(0xFF00F0FF),
              size: radius * 1.1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBotonPredeterminado(String texto) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F1A3A),
        foregroundColor: const Color(0xFF9E9AC8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF4A3E8D)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => _procesarOpcionRapida(texto),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
