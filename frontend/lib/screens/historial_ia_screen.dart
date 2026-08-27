import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'guia_detalle_screen.dart';
import 'package:intl/intl.dart';
import 'configuracion_screen.dart';
import 'app_bottom_navbar.dart';
import 'app_language.dart';

class FormateadorHistorial {
  /// Parsea cualquier string de fecha forzando la conversión UTC a hora local
  static DateTime parsearAHoraLocal(dynamic fechaRaw) {
    if (fechaRaw == null) return DateTime.now();

    if (fechaRaw is DateTime) {
      return fechaRaw.toLocal();
    }

    String fechaStr = fechaRaw.toString().trim();
    if (fechaStr.isEmpty) return DateTime.now();

    try {
      // Si la fecha viene del backend tipo "2026-08-24 08:50:00" o "2026-08-24T08:50:00",
      // aseguramos el formato ISO añadiendo 'T' si falta y 'Z' al final para marcar UTC.
      if (!fechaStr.contains('T') && fechaStr.contains(' ')) {
        fechaStr = fechaStr.replaceAll(' ', 'T');
      }
      if (!fechaStr.endsWith('Z') && !fechaStr.contains('+')) {
        fechaStr += 'Z';
      }

      // Al parsear un string con 'Z', Dart entiende 100% que es UTC 
      // y .toLocal() aplica la resta exacta a hora Colombia (UTC-5)
      return DateTime.parse(fechaStr).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Retorna la cabecera de la sección: "HOY", "AYER" o "dd/MM/yyyy"
  static String obtenerTituloSeccion(DateTime fechaLocal) {
    final ahora = DateTime.now();

    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaNormalizada =
        DateTime(fechaLocal.year, fechaLocal.month, fechaLocal.day);

    final diferenciaDias = hoy.difference(fechaNormalizada).inDays;

    if (diferenciaDias == 0) {
      return 'HOY';
    } else if (diferenciaDias == 1) {
      return 'AYER';
    } else {
      return DateFormat('dd/MM/yyyy').format(fechaLocal);
    } 
  }

  /// Formatea la hora individual en formato 12 horas AM/PM exacto (ej: 3:54 AM)
  static String obtenerHoraFormateada(DateTime fechaLocal) {
    return DateFormat('h:mm a').format(fechaLocal);
  }
}

class HistorialIAScreen extends StatefulWidget {
  final String userId;

  const HistorialIAScreen({super.key, required this.userId});

  @override
  State<HistorialIAScreen> createState() => _HistorialIAScreenState();
}

class _HistorialIAScreenState extends State<HistorialIAScreen> {
  bool _isLoading = true;
  List<dynamic> _historial = [];
  List<dynamic> _historialFiltrado = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
    _searchController.addListener(_filtrarHistorial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);

    final lista = await ApiService.obtenerHistorial(widget.userId);

    if (mounted) {
      setState(() {
        _historial = lista ?? [];
        _historialFiltrado = _historial;
        _isLoading = false;
      });
    }
  }

  void _filtrarHistorial() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _historialFiltrado = _historial.where((plan) {
        final nombre = (plan['nombre'] ?? '').toLowerCase();
        final descripcion = (plan['descripcion'] ?? '').toLowerCase();
        return nombre.contains(query) || descripcion.contains(query);
      }).toList();
    });
  }

  Future<void> _abrirPlan(String planId) async {
    setState(() => _isLoading = true);
    final plan = await ApiService.obtenerPlan(planId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el plan seleccionado.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GuiaDetalleScreen(guiaData: plan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar elementos por su cabecera de fecha usando FormateadorHistorial
    Map<String, List<dynamic>> grupos = {};
    for (var plan in _historialFiltrado) {
      final fechaRaw = plan['fecha_creacion'] ?? plan['created_at'];
      final fechaLocal = FormateadorHistorial.parsearAHoraLocal(fechaRaw);
      final cabecera = FormateadorHistorial.obtenerTituloSeccion(fechaLocal);

      if (!grupos.containsKey(cabecera)) {
        grupos[cabecera] = [];
      }
      grupos[cabecera]!.add(plan);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Historial IA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF00F0FF),
            onRefresh: _cargarHistorial,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 130.0, // Espacio para la barra de navegación
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.asset(
                        'logo/historial_lumi.png',
                        height: 190,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.smart_toy, size: 90, color: Color(0xFF00F0FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buscador
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar conversaciones con Lumi',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8B87BA),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8B87BA),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1736),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Listado agrupado por fechas
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                      ),
                    )
                  else if (_historialFiltrado.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No hay registros en el historial.',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ...grupos.entries.map((entry) {
                      String fechaTitulo = entry.key;
                      List<dynamic> planesDelDia = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado del Grupo (HOY, AYER, DD/MM/YYYY)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              fechaTitulo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          
                          // Tarjetas de planes
                          ...planesDelDia.map((plan) {
                            final fechaRaw = plan['fecha_creacion'] ?? plan['created_at'];
                            final fechaLocal = FormateadorHistorial.parsearAHoraLocal(fechaRaw);
                            final horaFormateada = FormateadorHistorial.obtenerHoraFormateada(fechaLocal);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  final planId = plan['id']?.toString();
                                  if (planId != null) _abrirPlan(planId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1736),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan['nombre'] ??
                                                  'Trabajo de flutter',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              plan['descripcion'] ??
                                                  'Desarrollo de app educativa',
                                              style: const TextStyle(
                                                color: Color(0xFF9E9AC8),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        horaFormateada,
                                        style: const TextStyle(
                                          color: Color(0xFF9E9AC8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: AppBottomNavbar(
              userId: widget.userId,
              currentIndex: 2,
              ),
            ),
        ),
        ],
      ),
    );
  }
}