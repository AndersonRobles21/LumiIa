import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'path_provider_stub.dart'
    if (dart.library.io) 'package:path_provider/path_provider.dart';

class AdminEstadisticasScreen extends StatefulWidget {
  final Map<String, dynamic> summary;
  final String adminUserId;

  const AdminEstadisticasScreen({
    super.key,
    required this.summary,
    required this.adminUserId,
  });

  @override
  State<AdminEstadisticasScreen> createState() =>
      _AdminEstadisticasScreenState();
}

class _AdminEstadisticasScreenState extends State<AdminEstadisticasScreen> {
  late Timer _refreshTimer;
  late Map<String, dynamic> _currentSummary;
  bool _isLoading = false;
  DateTime _lastUpdate = DateTime.now();
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _currentSummary = widget.summary;
    _loadAdminName();
    _initializeRefreshTimer();
  }

  Future<void> _loadAdminName() async {
    try {
      final profile = await ApiService.getProfile(widget.adminUserId);
      if (profile != null && mounted) {
        setState(() {
          _adminName =
              '${profile['nombre'] ?? 'Admin'} ${profile['apellido'] ?? ''}'
                  .trim();
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre del admin: $e');
    }
  }

  void _initializeRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadLatestSummary();
    });
  }

  Future<void> _loadLatestSummary() async {
    if (!mounted || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final summary = await ApiService.getAdminSummary(widget.adminUserId);
      if (mounted) {
        setState(() {
          _currentSummary = summary ?? {};
          _lastUpdate = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error actualizando datos: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _toSeries(List<dynamic>? rows) {
    if (rows == null) return const [];

    return rows.map((row) {
      final map = row is Map
          ? Map<String, dynamic>.from(row)
          : <String, dynamic>{};
      final fecha = (map['fecha'] ?? '').toString();
      final total = map['total'] is num ? (map['total'] as num).toInt() : 0;
      return {'fecha': fecha, 'total': total};
    }).toList();
  }

  String _sanitizeText(String? text) {
    if (text == null) return '';
    return text
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final planes = _toSeries(_currentSummary['planesPorDia'] as List<dynamic>?);
    final tareas = _toSeries(_currentSummary['tareasPorDia'] as List<dynamic>?);
    final completadas = _toSeries(
      _currentSummary['tareasCompletadasPorDia'] as List<dynamic>?,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF080D2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C4A),
        elevation: 0,
        title: Text(
          'Estadísticas • $_adminName',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Actualizado: ${_lastUpdate.hour.toString().padLeft(2, '0')}:${_lastUpdate.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ENCABEZADO CON LA IMAGEN DEL ROBOT MÁS GRANDE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agosto 24, 2026',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF7C9CFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Panel de control - Administrador',
                          style: GoogleFonts.orbitron(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Reportes y Estadísticas',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Visualiza el rendimiento y uso de la plataforma en tiempo real',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Imagen del robot con tamaño ampliado
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'logo/estadisticalumi.png', 
                      width: 180,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 150,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111C4A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF3D5AFE,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Color(0xFF00C2FF),
                          size: 45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- TARJETAS DE MÉTRICAS RÁPIDAS ---
              Row(
                children: [
                  _metricCard(
                    'Total usuarios',
                    (_currentSummary['totalUsuarios'] ?? 0).toString(),
                    Icons.group_rounded,
                  ),
                  const SizedBox(width: 10),
                  _metricCard(
                    'Estudiantes',
                    (_currentSummary['estudiantes'] ?? 0).toString(),
                    Icons.school_rounded,
                  ),
                  const SizedBox(width: 10),
                  _metricCard(
                    'Admins',
                    (_currentSummary['administradores'] ?? 0).toString(),
                    Icons.admin_panel_settings_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metricCard(
                    'Planes',
                    (_currentSummary['totalPlanes'] ?? 0).toString(),
                    Icons.assignment_rounded,
                  ),
                  const SizedBox(width: 10),
                  _metricCard(
                    'Tareas',
                    (_currentSummary['totalTareas'] ?? 0).toString(),
                    Icons.task_rounded,
                  ),
                  const SizedBox(width: 10),
                  _metricCard(
                    'Completadas',
                    (_currentSummary['tareasCompletadas'] ?? 0).toString(),
                    Icons.task_alt_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- BOTÓN DE DESCARGA PDF COMPLETO ---
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF716DC), Color(0xFFA41CF9)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF716DC).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async => await _onDownloadPdf(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'Descargar Reporte Ejecutivo (PDF)',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- GRÁFICOS ORGANIZADOS EN TARJETAS AMPLIAS ---
              _buildNeonChartCard(
                title: 'Progreso de estudiantes',
                subtitle: 'Completados vs En progreso',
                icon: Icons.school_rounded,
                data: planes,
                lineColor: const Color(0xFF00C2FF),
                secondaryColor: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 20),
              _buildNeonChartCard(
                title: 'Uso de la plataforma',
                subtitle: 'Usuarios activos y sesiones',
                icon: Icons.auto_graph_rounded,
                data: tareas,
                lineColor: const Color(0xFFF716DC),
                secondaryColor: const Color(0xFF0F1D8A),
              ),
              const SizedBox(height: 20),
              _buildNeonChartCard(
                title: 'Tareas Completadas (Mensual)',
                subtitle: 'Rendimiento general de cumplimiento',
                icon: Icons.insights_rounded,
                data: completadas,
                lineColor: const Color(0xFF22C55E),
                secondaryColor: const Color(0xFF00C2FF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeonChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, dynamic>> data,
    required Color lineColor,
    required Color secondaryColor,
  }) {
    final values = data.map((d) => (d['total'] as int)).toList();
    final double maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C4A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3D5AFE).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: lineColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lineColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: lineColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No hay datos suficientes para mostrar.',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _NeonLineChartPainter(
                  data: data,
                  maxValue: maxValue == 0 ? 1.0 : maxValue,
                  lineColor: lineColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111C4A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: const Color(0xFF00C2FF), size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GENERACIÓN DE PDF COMPLETO DE 4 PÁGINAS ---
  Future<void> _onDownloadPdf(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Generando reporte ejecutivo completo...')),
    );

    try {
      final pdf = pw.Document();

      // PÁGINA 1: PORTADA Y RESUMEN OPERATIVO
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LUMI ADMIN',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.purple900,
                          ),
                        ),
                        pw.Text(
                          'Sistema de Monitoreo Inteligente',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.purple100,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'REPORTE OFICIAL',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.purple900,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.purple900, thickness: 2),
                pw.SizedBox(height: 15),
                pw.Text(
                  'Reporte Ejecutivo General',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generado por: $_adminName | Fecha: ${DateTime.now().toString().split('.')[0]}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  '1. RESUMEN OPERATIVO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    _pdfTableRow(
                      'Usuarios Totales',
                      _sanitizeText(
                        (_currentSummary['totalUsuarios'] ?? 0).toString(),
                      ),
                    ),
                    _pdfTableRow(
                      'Estudiantes Registrados',
                      _sanitizeText(
                        (_currentSummary['estudiantes'] ?? 0).toString(),
                      ),
                    ),
                    _pdfTableRow(
                      'Administradores Activos',
                      _sanitizeText(
                        (_currentSummary['administradores'] ?? 0).toString(),
                      ),
                    ),
                    _pdfTableRow(
                      'Planes de Estudio Creados',
                      _sanitizeText(
                        (_currentSummary['totalPlanes'] ?? 0).toString(),
                      ),
                    ),
                    _pdfTableRow(
                      'Total de Tareas en Sistema',
                      _sanitizeText(
                        (_currentSummary['totalTareas'] ?? 0).toString(),
                      ),
                    ),
                    _pdfTableRow(
                      'Tareas Completadas',
                      _sanitizeText(
                        (_currentSummary['tareasCompletadas'] ?? 0).toString(),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  '2. INDICADORES DE RENDIMIENTO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple900,
                  ),
                ),
                pw.SizedBox(height: 8),
                _pdfIndicator(
                  'Tasa Global de Completación de Tareas',
                  _calculateCompletionRate(),
                ),
              ],
            );
          },
        ),
      );

      // PÁGINA 2: TENDENCIAS MENSUALES
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '3. TENDENCIAS MENSUALES',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple900,
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Planes de Estudio Creados por Mes',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeries(_currentSummary['planesPorDia']),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Tareas Registradas por Mes',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeries(_currentSummary['tareasPorDia']),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Tareas Completadas por Mes',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeries(_currentSummary['tareasCompletadasPorDia']),
              ],
            );
          },
        ),
      );

      // PÁGINA 3: ACTIVIDAD DETALLADA (ÚLTIMOS 30 DÍAS)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '4. ACTIVIDAD DETALLADA (ÚLTIMOS 30 DÍAS)',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple900,
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Planes de Estudio por Día',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeriesDetailado(
                  _currentSummary['planesPorDiaDetallado'],
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Tareas Generadas por Día',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeriesDetailado(
                  _currentSummary['tareasPorDiaDetallado'],
                ),
              ],
            );
          },
        ),
      );

      // PÁGINA 4: USUARIOS RECIENTEMENTE REGISTRADOS
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '5. USUARIOS RECIENTEMENTE REGISTRADOS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple900,
                  ),
                ),
                pw.SizedBox(height: 14),
                _pwTableUsuarios(_currentSummary['usuariosRecientes']),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      try {
        final pdfBytes = await pdf.save();
        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          if (directory != null) {
            final fileName =
                'LUMI_Reporte_Ejecutivo_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(pdfBytes);
            if (mounted)
              scaffold.showSnackBar(
                SnackBar(content: Text('✓ Reporte PDF guardado: $fileName')),
              );
          }
        }
      } catch (e) {
        debugPrint('Error guardando PDF local: $e');
      }
    } catch (e) {
      if (mounted)
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              'Error generando PDF: ${_sanitizeText(e.toString())}',
            ),
          ),
        );
    }
  }

  pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            _sanitizeText(label),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            _sanitizeText(value),
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfIndicator(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.purple50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _sanitizeText(label),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateCompletionRate() {
    final total = (_currentSummary['totalTareas'] ?? 0) as int;
    final completadas = (_currentSummary['tareasCompletadas'] ?? 0) as int;
    if (total == 0) return '0%';
    return '${((completadas / total) * 100).toStringAsFixed(1)}%';
  }

  pw.Widget _pwTableFromSeries(dynamic rows) {
    if (rows == null || (rows as List).isEmpty)
      return pw.Text(
        'Sin datos disponibles',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    final list = rows.cast<Map<String, dynamic>>();
    final data = list
        .map(
          (r) => [
            _sanitizeText((r['fecha'] ?? '').toString()),
            (r['total'] ?? '').toString(),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Periodo (Mes)', 'Cantidad Registrada'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple900),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(5),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  pw.Widget _pwTableFromSeriesDetailado(dynamic rows) {
    if (rows == null || (rows as List).isEmpty)
      return pw.Text(
        'Sin datos en los últimos 30 días',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    final list = rows.cast<Map<String, dynamic>>();
    final data = list
        .map(
          (r) => [
            _sanitizeText((r['fecha'] ?? '').toString()),
            (r['total'] ?? '').toString(),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Fecha Específica', 'Cantidad'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple800),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(4),
      cellStyle: const pw.TextStyle(fontSize: 8),
    );
  }

  pw.Widget _pwTableUsuarios(dynamic rows) {
    if (rows == null || (rows as List).isEmpty)
      return pw.Text(
        'Sin usuarios recientes',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    final list = rows.cast<Map<String, dynamic>>();
    final data = list.map((r) {
      final nombre = _sanitizeText(
        '${r['nombre'] ?? ''} ${r['apellido'] ?? ''}'.trim(),
      );
      final tipo = (r['es_admin'] == true) ? 'Admin' : 'Estudiante';
      final fecha = (r['fecha_registro'] ?? '').toString().split('T')[0];
      final planes = (r['planes_count'] ?? 0).toString();
      final tareas = (r['tareas_count'] ?? 0).toString();
      return [nombre, tipo, fecha, planes, tareas];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Nombre del Usuario', 'Rol', 'Registro', 'Planes', 'Tareas'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple900),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(4),
      cellStyle: const pw.TextStyle(fontSize: 8),
    );
  }
}

class _NeonLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;
  final Color lineColor;
  final Color secondaryColor;

  _NeonLineChartPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintGlow = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintPointBorder = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = <Offset>[];

    final double stepX = size.width / (data.length > 1 ? data.length - 1 : 1);
    const double paddingBottom = 24.0;
    const double paddingTop = 16.0;
    final double usableHeight = size.height - paddingBottom - paddingTop;

    for (int i = 0; i < data.length; i++) {
      final value = (data[i]['total'] as int).toDouble();
      final x = i * stepX;
      final y = size.height - paddingBottom - (value / maxValue) * usableHeight;
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintGlow);
    canvas.drawPath(path, paintLine);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4.5, paintPoint);
      canvas.drawCircle(points[i], 4.5, paintPointBorder);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final label = item['fecha'].toString().contains('-')
          ? _getShortMonth(item['fecha'].toString())
          : item['fecha'].toString();
      final valueStr = item['total'].toString();

      textPainter.text = TextSpan(
        text: label,
        style: GoogleFonts.orbitron(color: Colors.white60, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, size.height - 18),
      );

      textPainter.text = TextSpan(
        text: valueStr,
        style: GoogleFonts.orbitron(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 18),
      );
    }
  }

  String _getShortMonth(String dateStr) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 2) {
        final monthIdx = int.parse(parts[1]) - 1;
        if (monthIdx >= 0 && monthIdx < 12) return months[monthIdx];
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
