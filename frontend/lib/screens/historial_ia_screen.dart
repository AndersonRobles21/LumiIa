import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_bottom_navbar.dart';
import 'app_language.dart';
import 'guia_detalle_screen.dart';

class FormateadorHistorial {
  static DateTime parsearAHoraLocal(dynamic fechaRaw) {
    if (fechaRaw == null) return DateTime.now();

    if (fechaRaw is DateTime) {
      return fechaRaw.toLocal();
    }

    var fechaStr = fechaRaw.toString().trim();
    if (fechaStr.isEmpty) return DateTime.now();

    try {
      if (!fechaStr.contains('T') && fechaStr.contains(' ')) {
        fechaStr = fechaStr.replaceAll(' ', 'T');
      }

      if (!fechaStr.endsWith('Z') && !fechaStr.contains('+')) {
        fechaStr += 'Z';
      }

      return DateTime.parse(fechaStr).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static String obtenerTituloSeccion(DateTime fechaLocal) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fecha = DateTime(
      fechaLocal.year,
      fechaLocal.month,
      fechaLocal.day,
    );

    final diferenciaDias = hoy.difference(fecha).inDays;

    if (diferenciaDias == 0) {
      return appLanguageText('HOY', 'TODAY');
    }

    if (diferenciaDias == 1) {
      return appLanguageText('AYER', 'YESTERDAY');
    }

    return DateFormat('dd/MM/yyyy').format(fechaLocal);
  }

  static String obtenerHoraFormateada(DateTime fechaLocal) {
    return DateFormat(
      'h:mm a',
      AppLanguage.instance.isEnglish ? 'en_US' : 'es_CO',
    ).format(fechaLocal);
  }
}

class HistorialIAScreen extends StatefulWidget {
  final String userId;

  const HistorialIAScreen({
    super.key,
    required this.userId,
  });

  @override
  State<HistorialIAScreen> createState() => _HistorialIAScreenState();
}

class _HistorialIAScreenState extends State<HistorialIAScreen>
    with AppLanguageListenerMixin<HistorialIAScreen> {
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

    if (!mounted) return;

    setState(() {
      _historial = lista ?? [];
      _historialFiltrado = _historial;
      _isLoading = false;
    });
  }

  void _filtrarHistorial() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _historialFiltrado = _historial.where((plan) {
        final nombre = (plan['nombre'] ?? '').toString().toLowerCase();
        final descripcion =
            (plan['descripcion'] ?? '').toString().toLowerCase();

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
        SnackBar(
          content: Text(
            tr(
              'No se pudo cargar el plan seleccionado.',
              'Could not load the selected plan.',
            ),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuiaDetalleScreen(guiaData: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<dynamic>>{};

    for (final plan in _historialFiltrado) {
      final fechaRaw = plan['fecha_creacion'] ?? plan['created_at'];
      final fechaLocal = FormateadorHistorial.parsearAHoraLocal(fechaRaw);
      final cabecera = FormateadorHistorial.obtenerTituloSeccion(fechaLocal);

      grupos.putIfAbsent(cabecera, () => []);
      grupos[cabecera]!.add(plan);
    }

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      extendBodyBehindAppBar: Responsive.esEscritorio(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr('Historial IA', 'AI History'),
          style: TextStyle(
            color: LumiAppTheme.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(
          color: LumiAppTheme.primaryText(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: Responsive.esEscritorio(context)
                  ? Responsive.anchoSidebar(context)
                  : 0,
            ),
            child: RefreshIndicator(
              color: const Color(0xFF00F0FF),
              backgroundColor: LumiAppTheme.surface(context),
              onRefresh: _cargarHistorial,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: Responsive.esEscritorio(context) ? 4 : 16,
                  bottom: Responsive.esEscritorio(context) ? 28 : 130,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Responsive.esEscritorio(context))
                      SizedBox(
                        height:
                            MediaQuery.paddingOf(context).top + kToolbarHeight,
                      ),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: Responsive.esMovil(context)
                                ? 140
                                : Responsive.esEscritorio(context)
                                    ? 124
                                    : 190,
                          ),
                          child: Image.asset(
                            'logo/historial_lumi.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.smart_toy,
                              size: 90,
                              color: Color(0xFF00F0FF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: Responsive.esEscritorio(context) ? 14 : 24,
                    ),
                    TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: LumiAppTheme.primaryText(context),
                      ),
                      decoration: InputDecoration(
                        hintText: tr(
                          'Buscar conversaciones con Lumi',
                          'Search conversations with Lumi',
                        ),
                        hintStyle: const TextStyle(
                          color: Color(0xFF8B87BA),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF8B87BA),
                        ),
                        filled: true,
                        fillColor: LumiAppTheme.surface(context),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: _searchBorder(),
                        enabledBorder: _searchBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color(0xFF00F0FF),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                      )
                    else if (_historialFiltrado.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            tr(
                              'No hay registros en el historial.',
                              'There are no history records.',
                            ),
                            style: TextStyle(
                              color: LumiAppTheme.secondaryText(context),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ...grupos.entries.map(
                        (entry) => _buildDateGroup(
                          context,
                          fechaTitulo: entry.key,
                          planes: entry.value,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          AppBottomNavbar(
            userId: widget.userId,
            currentIndex: 2,
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _searchBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
        width: 0.8,
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context, {
    required String fechaTitulo,
    required List<dynamic> planes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            fechaTitulo,
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ...planes.map((plan) => _buildPlanCard(context, plan)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, dynamic plan) {
    final fechaRaw = plan['fecha_creacion'] ?? plan['created_at'];
    final fechaLocal = FormateadorHistorial.parsearAHoraLocal(fechaRaw);
    final hora = FormateadorHistorial.obtenerHoraFormateada(fechaLocal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          final planId = plan['id']?.toString();

          if (planId != null) {
            _abrirPlan(planId);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: LumiAppTheme.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D4BC1).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['nombre'] ??
                          tr('Trabajo de Flutter', 'Flutter work'),
                      style: TextStyle(
                        color: LumiAppTheme.primaryText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['descripcion'] ??
                          tr(
                            'Desarrollo de app educativa',
                            'Educational app development',
                          ),
                      style: TextStyle(
                        color: LumiAppTheme.secondaryText(context),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hora,
                style: TextStyle(
                  color: LumiAppTheme.secondaryText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}