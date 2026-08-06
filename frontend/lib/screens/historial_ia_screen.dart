import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'app_bottom_navbar.dart';
import 'app_language.dart';
import 'guia_detalle_screen.dart';

class HistorialIAScreen extends StatefulWidget {
  final String userId;

  const HistorialIAScreen({super.key, required this.userId});

  @override
  State<HistorialIAScreen> createState() => _HistorialIAScreenState();
}

class _HistorialIAScreenState extends State<HistorialIAScreen> {
  bool _isLoading = true;
  List<dynamic> _historial = [];

  @override
  void initState() {
    super.initState();
    // Nos suscribimos a cambios de idioma para que la pantalla se
    // reconstruya en cuanto alguien cambie ES/EN desde Configuración.
    AppLanguage.instance.addListener(_onLanguageChanged);
    _cargarHistorial();
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);

    final lista = await ApiService.obtenerHistorial(widget.userId);

    if (mounted) {
      setState(() {
        _historial = lista ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirPlan(String planId) async {
    setState(() => _isLoading = true);

    final plan = await ApiService.obtenerPlan(planId);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLanguage.instance.t('history_plan_error'))),
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

  String _formatFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr).toLocal();
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (_) {
      return fechaStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(lang.t('history_title')),
        centerTitle: true,
      ),
      // Stack para poder flotar la barra de navegación inferior encima
      // del contenido, igual que en Dashboard y Perfil. Va dentro de un
      // SafeArea para que la barra quede a la misma altura visual que en
      // esas pantallas (si no, se pega hasta el borde físico de abajo).
      body: SafeArea(
        child: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFFFF44AA),
            onRefresh: _cargarHistorial,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1A3A).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.t('history_intro_1'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lang.t('history_intro_2'),
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF44AA)),
                    )
                  else if (_historial.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          lang.t('history_empty'),
                          style: const TextStyle(color: Colors.white38, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _historial.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final plan = _historial[index];
                        final fecha = plan['fecha_creacion'] != null
                            ? _formatFecha(plan['fecha_creacion'].toString())
                            : '';
                        return GestureDetector(
                          onTap: () {
                            final planId = plan['id']?.toString();
                            if (planId != null) {
                              _abrirPlan(planId);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1A3A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan['nombre'] ??
                                      lang.t('history_default_plan_name'),
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  plan['descripcion'] ?? '',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      plan['metodo_estudio'] ?? '',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                    Text(
                                      fecha,
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          // Barra inferior: currentIndex 2 = ícono de IA/Historial resaltado.
          AppBottomNavbar(userId: widget.userId, currentIndex: 2),
        ],
        ),
      ),
    );
  }
}