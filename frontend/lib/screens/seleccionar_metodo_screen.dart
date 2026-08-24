import 'package:flutter/material.dart';
import '/services/api_service.dart';

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

class _SeleccionarMetodoScreenState extends State<SeleccionarMetodoScreen> {
  late String _metodoActual;

  final List<Map<String, dynamic>> _metodos = [
    {
      'id': 'Método Feynman',
      'titulo': 'Método Feynman',
      'subtitulo': 'Explica para aprender',
      'descripcion':
          'Si no puedes explicarlo de forma sencilla, no lo has entendido bien.',
      'icono': Icons.lightbulb,
      'colorIcono': Colors.amber,
    },
    {
      'id': 'Técnica Pomodoro',
      'titulo': 'Técnica Pomodoro',
      'subtitulo': 'Gestión del tiempo',
      'descripcion':
          'Alterna bloques de estudio intenso con descansos cortos.',
      'icono': Icons.timer_outlined,
      'colorIcono': const Color(0xFF00F0FF),
    },
    {
      'id': 'Active Recall',
      'titulo': 'Active Recall',
      'subtitulo': 'Recordatorio activo',
      'descripcion':
          'Fuerza a tu cerebro a recuperar información de la memoria sin ayuda.',
      'icono': Icons.psychology,
      'colorIcono': const Color(0xFFFF44AA),
    },
    {
      'id': 'Spaced Repetition',
      'titulo': 'Spaced Repetition',
      'subtitulo': 'Repetición espaciada',
      'descripcion':
          'Repasa los temas en intervalos de tiempo crecientes para consolidar la memoria.',
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

    // Devuelve el ID seleccionado de inmediato al chat para que proceda a actualizar la BD
    if (mounted) {
      Navigator.pop(context, id);
    }
  }

  bool _esElRecomendado(String idMetodo) {
    final rec = widget.metodoRecomendado.toLowerCase();
    final id = idMetodo.toLowerCase();
    return rec.contains(id) || id.contains(rec);
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF110D27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161331),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1F1A3A),
              child: ClipOval(
                child: Image.asset(
                  'logo/chat_ia.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
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
                style: const TextStyle(
                  color: Colors.white,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 12),
                      Text(
                        'Métodos de Estudio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selecciona el método que mejor se adapte a tu objetivo actual.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: anchoPantalla * 0.45,
                  height: anchoPantalla * 0.45,
                  child: Image.asset(
                    'logo/metodos.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.smart_toy,
                      color: Color(0xFF00F0FF),
                      size: 110,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ..._metodos.map((m) {
              final esRecomendado = _esElRecomendado(m['id']);
              final esSeleccionado = m['id'] == _metodoActual;

              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => _seleccionar(m['id']),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF231D45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: esSeleccionado
                                ? const Color(0xFFBD00FF)
                                : esRecomendado
                                    ? const Color(0xFFBD00FF).withOpacity(0.6)
                                    : const Color(0xFF382F6B),
                            width: esSeleccionado || esRecomendado ? 2 : 1,
                          ),
                          boxShadow: esSeleccionado
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFBD00FF)
                                        .withOpacity(0.35),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
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
                                m['icono'] as IconData,
                                color: m['colorIcono'] as Color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['titulo'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
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
                                      m['subtitulo'],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    m['descripcion'],
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
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
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Recomendado por Lumi',
                                style: TextStyle(
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