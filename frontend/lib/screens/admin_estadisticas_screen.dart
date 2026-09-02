import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class AdminEstadisticasScreen extends StatelessWidget {
  final Map<String, dynamic> summary;
  final String adminUserId;

  const AdminEstadisticasScreen({super.key, required this.summary, required this.adminUserId});

  List<Map<String, dynamic>> _toSeries(List<dynamic>? rows) {
    if (rows == null) return const [];

    return rows.map((row) {
      final map = row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{};
      final fecha = (map['fecha'] ?? '').toString();
      final total = map['total'] is num ? (map['total'] as num).toInt() : 0;
      return {'fecha': fecha, 'total': total};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final planes = _toSeries(summary['planesPorDia'] as List<dynamic>?);
    final tareas = _toSeries(summary['tareasPorDia'] as List<dynamic>?);
    final completadas = _toSeries(summary['tareasCompletadasPorDia'] as List<dynamic>?);

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
                  children: data.take(7).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final value = (item['total'] as int?) ?? 0;
                    final barHeight = maxValue == 0 ? 0.0 : (value / maxValue) * 150;
                    final label = (item['fecha'] as String).split('-').last;

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
                              label,
                              style: const TextStyle(color: Colors.white60, fontSize: 9),
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
          'Estadísticas LUMI',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _metricCard('Total usuarios', (summary['totalUsuarios'] ?? 0).toString()),
                  const SizedBox(width: 12),
                  _metricCard('Estudiantes', (summary['estudiantes'] ?? 0).toString()),
                  const SizedBox(width: 12),
                      _metricCard('Admins', (summary['administradores'] ?? 0).toString()),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    await _onDownloadPdf(context);
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Descargar PDF'),
                ),
              ),
              const SizedBox(height: 12),
              chartCard('Planes creados', planes, color: const Color(0xFF00C2FF)),
              const SizedBox(height: 20),
              chartCard('Tareas registradas', tareas, color: const Color(0xFF7C3AED)),
              const SizedBox(height: 20),
              chartCard('Tareas completadas', completadas, color: const Color(0xFF22C55E)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDownloadPdf(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text('Generando PDF...')));

    try {
        // Obtener lista de usuarios reales usando el adminUserId proporcionado.
        final usuarios = adminUserId.isNotEmpty ? await ApiService.getAdminUsuarios(adminUserId) : const [];

      // Para cada usuario obtener detalle (planes, tareas, medallas)
      final List<Map<String, dynamic>> usuariosDetalles = [];
      for (final u in usuarios) {
        try {
          final id = (u['id'] ?? '').toString();
          if (id.isEmpty) continue;
          final detalle = await ApiService.getAdminUsuarioDetalle(adminUserId, id);
          if (detalle != null) {
            usuariosDetalles.add({
              'usuario': u,
              'detalle': detalle,
            });
          } else {
            usuariosDetalles.add({'usuario': u, 'detalle': null});
          }
        } catch (_) {
          usuariosDetalles.add({'usuario': u, 'detalle': null});
        }
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return [
              pw.Header(level: 0, child: pw.Text('Reporte administrativo LUMI', style: pw.TextStyle(fontSize: 20))),
              pw.Paragraph(text: 'Resumen generado en tiempo real con datos de la base de datos.'),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Métrica', 'Valor'],
                data: [
                  ['Usuarios totales', (summary['totalUsuarios'] ?? 0).toString()],
                  ['Estudiantes', (summary['estudiantes'] ?? 0).toString()],
                  ['Administradores', (summary['administradores'] ?? 0).toString()],
                  ['Planes (totales)', (summary['totalPlanes'] ?? 0).toString()],
                  ['Tareas (totales)', (summary['totalTareas'] ?? 0).toString()],
                  ['Tareas completadas', (summary['tareasCompletadas'] ?? 0).toString()],
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Header(level: 1, child: pw.Text('Usuarios')),
              pw.Column(children: usuariosDetalles.map((entry) {
                final user = entry['usuario'] ?? {};
                final det = entry['detalle'];
                final nombre = (user['nombre'] ?? '').toString();
                final apellido = (user['apellido'] ?? '').toString();
                final fecha = (user['fecha_registro'] ?? '').toString();
                final objetivo = (user['objetivo'] ?? '').toString();
                final racha = (user['racha'] ?? '').toString();
                final planesCount = det != null && det['planes'] is List ? (det['planes'] as List).length : 0;
                final tareasCount = det != null && det['tareas'] is List ? (det['tareas'] as List).length : 0;
                final medallasCount = det != null && det['medallas'] is List ? (det['medallas'] as List).length : 0;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('$nombre $apellido', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Registro: $fecha'),
                      if (objetivo.isNotEmpty) pw.Text('Objetivo: $objetivo'),
                      pw.Text('Racha: $racha  •  Planes: $planesCount  •  Tareas: $tareasCount  •  Medallas: $medallasCount'),
                    ],
                  ),
                );
              }).toList()),
              pw.SizedBox(height: 12),
              pw.Header(level: 1, child: pw.Text('Series')),
              pw.Text('Planes por día'),
              _pwTableFromSeries(summary['planesPorDia']),
              pw.SizedBox(height: 8),
              pw.Text('Tareas por día'),
              _pwTableFromSeries(summary['tareasPorDia']),
              pw.SizedBox(height: 8),
              pw.Text('Tareas completadas por día'),
              _pwTableFromSeries(summary['tareasCompletadasPorDia']),
            ];
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      scaffold.showSnackBar(const SnackBar(content: Text('PDF generado correctamente.')));
    } catch (e) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
    }
  }

  pw.Widget _pwTableFromSeries(dynamic rows) {
    if (rows == null) return pw.Container(child: pw.Text('No hay datos.'));
    final list = (rows as List).map((r) => r as Map<String, dynamic>).toList();
    final data = list.map((r) => [(r['fecha'] ?? '').toString(), (r['total'] ?? '').toString()]).toList();
    return pw.Table.fromTextArray(headers: ['Fecha', 'Total'], data: data);
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
