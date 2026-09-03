import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AdminEstadisticasScreen extends StatefulWidget {
  final Map<String, dynamic> summary;
  final String adminUserId;

  const AdminEstadisticasScreen({super.key, required this.summary, required this.adminUserId});

  @override
  State<AdminEstadisticasScreen> createState() => _AdminEstadisticasScreenState();
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
          _adminName = '${profile['nombre'] ?? 'Admin'} ${profile['apellido'] ?? ''}'.trim();
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre del admin: $e');
    }
  }

  void _initializeRefreshTimer() {
    // Actualizar datos cada 10 segundos
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
      final map = row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{};
      final fecha = (map['fecha'] ?? '').toString();
      final total = map['total'] is num ? (map['total'] as num).toInt() : 0;
      return {'fecha': fecha, 'total': total};
    }).toList();
  }

  String _sanitizeText(String? text) {
    if (text == null) return '';
    return text
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Elimina caracteres no ASCII
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .trim();
  }

  String _getMonthName(String monthStr) {
    if (monthStr.isEmpty || !monthStr.contains('-')) return monthStr;
    final parts = monthStr.split('-');
    if (parts.length < 2) return monthStr;
    
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    try {
      final monthNum = int.parse(parts[1]);
      return months[monthNum - 1];
    } catch (e) {
      return monthStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planes = _toSeries(_currentSummary['planesPorDia'] as List<dynamic>?);
    final tareas = _toSeries(_currentSummary['tareasPorDia'] as List<dynamic>?);
    final completadas = _toSeries(_currentSummary['tareasCompletadasPorDia'] as List<dynamic>?);

    Widget chartCard(String title, List<Map<String, dynamic>> data, {Color color = const Color(0xFF7C3AED)}) {
      final maxValue = data.isEmpty ? 1 : data.map((d) => (d['total'] as int)).reduce((a, b) => a > b ? a : b);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111C4A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No hay datos para mostrar.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.take(12).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final value = (item['total'] as int?) ?? 0;
                    final barHeight = maxValue == 0 ? 0.0 : (value / maxValue) * 150;
                    final monthLabel = _getMonthName((item['fecha'] as String));

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 4, right: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              value.toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: barHeight,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [color, color.withValues(alpha: 0.45)],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              monthLabel,
                              style: const TextStyle(color: Colors.white60, fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080D2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C4A),
        foregroundColor: Colors.white,
        title: Text(
          'Estadísticas • $_adminName',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Actualizado: ${_lastUpdate.hour.toString().padLeft(2, '0')}:${_lastUpdate.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
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
              Row(
                children: [
                  _metricCard('Total usuarios', (_currentSummary['totalUsuarios'] ?? 0).toString()),
                  const SizedBox(width: 12),
                  _metricCard('Estudiantes', (_currentSummary['estudiantes'] ?? 0).toString()),
                  const SizedBox(width: 12),
                  _metricCard('Admins', (_currentSummary['administradores'] ?? 0).toString()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _metricCard('Planes', (_currentSummary['totalPlanes'] ?? 0).toString()),
                  const SizedBox(width: 12),
                  _metricCard('Tareas', (_currentSummary['totalTareas'] ?? 0).toString()),
                  const SizedBox(width: 12),
                  _metricCard('Completadas', (_currentSummary['tareasCompletadas'] ?? 0).toString()),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF44AA)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await _onDownloadPdf(context);
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Descargar PDF'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              chartCard('Planes creados (Mensual)', planes, color: const Color(0xFF00C2FF)),
              const SizedBox(height: 20),
              chartCard('Tareas registradas (Mensual)', tareas, color: const Color(0xFF7C3AED)),
              const SizedBox(height: 20),
              chartCard('Tareas completadas (Mensual)', completadas, color: const Color(0xFF22C55E)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDownloadPdf(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text('Generando PDF ejecutivo...')));

    try {
      final pdf = pw.Document();

      // Página 1: Resumen Ejecutivo
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'LUMI ADMIN',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'Reporte Ejecutivo - Estadisticas Mensuales',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generado: ${DateTime.now().toString().split('.')[0]}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Seccion: Resumen Operativo
                pw.Text(
                  'RESUMEN OPERATIVO',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    _pdfTableRow('Usuarios Totales', _sanitizeText((_currentSummary['totalUsuarios'] ?? 0).toString())),
                    _pdfTableRow('Estudiantes', _sanitizeText((_currentSummary['estudiantes'] ?? 0).toString())),
                    _pdfTableRow('Administradores', _sanitizeText((_currentSummary['administradores'] ?? 0).toString())),
                    _pdfTableRow('Planes de Estudio', _sanitizeText((_currentSummary['totalPlanes'] ?? 0).toString())),
                    _pdfTableRow('Total de Tareas', _sanitizeText((_currentSummary['totalTareas'] ?? 0).toString())),
                    _pdfTableRow('Tareas Completadas', _sanitizeText((_currentSummary['tareasCompletadas'] ?? 0).toString())),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Tasa de Completacion
                pw.Text(
                  'INDICADORES CLAVE',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfIndicator(
                  'Tasa de Completacion de Tareas',
                  _calculateCompletionRate(),
                ),
              ],
            );
          },
        ),
      );

      // Página 2: Series Mensuales + Diarias
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TENDENCIAS MENSUALES',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Planes por mes
                pw.Text(
                  'Planes de Estudio Creados (Mensual)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeries(_currentSummary['planesPorDia']),
                pw.SizedBox(height: 12),

                // Tareas por mes
                pw.Text(
                  'Tareas Registradas (Mensual)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeries(_currentSummary['tareasPorDia']),
                pw.SizedBox(height: 12),

                // Tareas completadas por mes
                pw.Text(
                  'Tareas Completadas (Mensual)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeries(_currentSummary['tareasCompletadasPorDia']),
              ],
            );
          },
        ),
      );

      // Página 3: Datos Diarios Detallados
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ACTIVIDAD DETALLADA (ÚLTIMOS 30 DÍAS)',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 12),

                // Planes por día
                pw.Text(
                  'Planes de Estudio por Día',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeriesDetailado(_currentSummary['planesPorDiaDetallado']),
                pw.SizedBox(height: 12),

                // Tareas por día
                pw.Text(
                  'Tareas por Día',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 6),
                _pwTableFromSeriesDetailado(_currentSummary['tareasPorDiaDetallado']),
              ],
            );
          },
        ),
      );

      // Página 4: Usuarios Recientemente Creados
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'USUARIOS RECIENTEMENTE CREADOS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 12),
                _pwTableUsuarios(_currentSummary['usuariosRecientes']),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      
      // Guardar el PDF en la carpeta de descargas con mejor manejo de errores
      try {
        final pdfBytes = await pdf.save();
        
        // Obtener ruta de descargas según plataforma
        late String downloadPath;
        late String displayPath;
        
        try {
          if (Platform.isAndroid || Platform.isIOS) {
            final directory = await getApplicationDocumentsDirectory();
            downloadPath = directory.path;
            displayPath = 'Documentos de la app';
          } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            final directory = await getDownloadsDirectory();
            if (directory != null) {
              downloadPath = directory.path;
              displayPath = 'Carpeta de Descargas';
            } else {
              throw Exception('No se pudo obtener la carpeta de Descargas');
            }
          } else {
            throw Exception('Plataforma no soportada');
          }
        } catch (pathError) {
          debugPrint('Error obteniendo ruta: $pathError');
          if (mounted) {
            scaffold.showSnackBar(SnackBar(content: Text('Error al obtener ruta de descargas: $pathError')));
          }
          return;
        }
        
        // Crear nombre de archivo único con timestamp
        final fileName = 'LUMI_Reporte_${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour.toString().padLeft(2, '0')}-${DateTime.now().minute.toString().padLeft(2, '0')}-${DateTime.now().second.toString().padLeft(2, '0')}.pdf';
        final filePath = '$downloadPath/$fileName';
        
        // Escribir archivo
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        
        // Verificar que el archivo se creó
        if (await file.exists()) {
          final fileSize = await file.length();
          if (mounted) {
            scaffold.showSnackBar(SnackBar(
              content: Text('✓ PDF guardado en $displayPath\nArchivo: $fileName\nTamaño: ${(fileSize / 1024).toStringAsFixed(2)} KB'),
              duration: const Duration(seconds: 4),
            ));
          }
          debugPrint('PDF guardado exitosamente en: $filePath ($fileSize bytes)');
        } else {
          throw Exception('El archivo no se creó correctamente');
        }
      } catch (saveError) {
        debugPrint('Error guardando PDF: $saveError');
        if (mounted) {
          scaffold.showSnackBar(SnackBar(
            content: Text('Error guardando PDF: ${_sanitizeText(saveError.toString())}'),
            duration: const Duration(seconds: 3),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Error: ${_sanitizeText(e.toString())}')));
      }
    }
  }

  pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            _sanitizeText(label),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            _sanitizeText(value),
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfIndicator(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _sanitizeText(label),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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

    final porcentaje = ((completadas / total) * 100).toStringAsFixed(1);
    return '$porcentaje%';
  }

  pw.Widget _pwTableFromSeries(dynamic rows) {
    if (rows == null) return pw.Text('Sin datos');
    final list = (rows as List).cast<Map<String, dynamic>>();
    
    final data = list.map((r) {
      final fecha = _sanitizeText((r['fecha'] ?? '').toString());
      final total = (r['total'] ?? '').toString();
      return [fecha, total];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Mes', 'Cantidad'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  pw.Widget _pwTableFromSeriesDetailado(dynamic rows) {
    if (rows == null) return pw.Text('Sin datos');
    final list = (rows as List).cast<Map<String, dynamic>>();
    
    if (list.isEmpty) return pw.Text('Sin datos en los últimos 30 días');
    
    final data = list.map((r) {
      final fecha = _sanitizeText((r['fecha'] ?? '').toString());
      final total = (r['total'] ?? '').toString();
      return [fecha, total];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Fecha', 'Cantidad'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(5),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  pw.Widget _pwTableUsuarios(dynamic rows) {
    if (rows == null) return pw.Text('Sin datos');
    final list = (rows as List).cast<Map<String, dynamic>>();
    
    if (list.isEmpty) return pw.Text('Sin usuarios recientemente creados');
    
    final data = list.map((r) {
      final nombreCompleto = '${r['nombre'] ?? ''} ${r['apellido'] ?? ''}'.trim();
      final nombre = _sanitizeText(nombreCompleto);
      final tipo = (r['es_admin'] == true) ? 'Admin' : 'Estudiante';
      final fecha = _formatDate((r['fecha_registro'] ?? '').toString());
      final planes = (r['planes_count'] ?? 0).toString();
      final tareas = (r['tareas_count'] ?? 0).toString();
      return [nombre, tipo, fecha, planes, tareas];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Nombre', 'Tipo', 'Fecha Registro', 'Planes', 'Tareas'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(5),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return '';
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _metricCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151C3D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
