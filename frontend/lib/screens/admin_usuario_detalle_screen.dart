import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AdminUsuarioDetalleScreen extends StatefulWidget {
  final String adminUserId;
  final String targetUserId;

  const AdminUsuarioDetalleScreen({
    super.key,
    required this.adminUserId,
    required this.targetUserId,
  });

  @override
  State<AdminUsuarioDetalleScreen> createState() => _AdminUsuarioDetalleScreenState();
}

class _AdminUsuarioDetalleScreenState extends State<AdminUsuarioDetalleScreen> {
  bool _loading = true;
  Map<String, dynamic> _usuario = {};
  List<dynamic> _planes = [];
  List<dynamic> _tareas = [];
  List<dynamic> _medallas = [];
  List<dynamic> _horarios = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final data = await ApiService.getAdminUsuarioDetalle(widget.adminUserId, widget.targetUserId);

    if (!mounted) return;

    setState(() {
      _usuario = data?['usuario'] is Map ? Map<String, dynamic>.from(data!['usuario']) : {};
      _planes = data?['planes'] is List ? data!['planes'] as List : const [];
      _tareas = data?['tareas'] is List ? data!['tareas'] as List : const [];
      _medallas = data?['medallas'] is List ? data!['medallas'] as List : const [];
      _horarios = data?['horarios'] is List ? data!['horarios'] as List : const [];
      _loading = false;
    });
  }

  Future<void> _editarNombre() async {
    final nombreCtrl = TextEditingController(text: (_usuario['nombre'] ?? '').toString());
    final apellidoCtrl = TextEditingController(text: (_usuario['apellido'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E142C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFFF716DC).withValues(alpha: 0.3)),
          ),
          title: Text('Editar nombre', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(color: Color(0xFFB0AEC4)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4A2A68))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF716DC))),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: apellidoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  labelStyle: const TextStyle(color: Color(0xFFB0AEC4)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4A2A68))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF716DC))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFFB0AEC4))),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(colors: [Color(0xFFF716DC), Color(0xFFA41CF9)]),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final updated = await ApiService.updateAdminUserName(
      adminUserId: widget.adminUserId,
      targetUserId: widget.targetUserId,
      nombre: nombreCtrl.text,
      apellido: apellidoCtrl.text,
    );

    if (!mounted) return;

    if (updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Nombre actualizado correctamente.')),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo actualizar el nombre.')),
      );
    }
  }

  Future<void> _eliminarUsuario() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E142C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        title: Text('Eliminar usuario', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Esta acción elimina el perfil, planes, tareas y dependencias asociadas al usuario. ¿Continuar?',
          style: TextStyle(color: Color(0xFFB0AEC4)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Color(0xFFB0AEC4)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final deleted = await ApiService.deleteAdminUser(
      adminUserId: widget.adminUserId,
      targetUserId: widget.targetUserId,
    );

    if (!mounted) return;

    if (deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Usuario eliminado correctamente.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo eliminar el usuario.')),
      );
    }
  }

  Future<void> _delegarAEstudiante() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E142C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFF00C2FF).withValues(alpha: 0.5)),
        ),
        title: Text('Delegar administrador', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'El usuario volverá a ser estudiante. Se conservarán su perfil, foto, tareas, planes y progreso.',
          style: TextStyle(color: Color(0xFFB0AEC4)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Color(0xFFB0AEC4)))),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF7C3AED)]),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              child: const Text('Delegar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final delegated = await ApiService.delegateAdminUser(
      adminUserId: widget.adminUserId,
      targetUserId: widget.targetUserId,
    );

    if (!mounted) return;

    if (delegated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Administrador delegado a estudiante.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al delegar el administrador.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (_usuario['nombre'] ?? 'Usuario').toString();
    final apellido = (_usuario['apellido'] ?? '').toString();
    final objetivo = (_usuario['objetivo'] ?? '').toString();
    final esAdmin = (_usuario['es_admin'] ?? false) == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16003A),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          esAdmin ? 'Detalle de Administrador' : 'Detalle de Estudiante',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: _editarNombre,
            tooltip: 'Editar nombre',
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF00C2FF)),
          ),
          if (!esAdmin)
            IconButton(
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E142C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: const Color(0xFFF716DC).withValues(alpha: 0.5)),
                    ),
                    title: Text('Promover a administrador', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    content: const Text('¿Deseas promover este usuario a administrador?', style: TextStyle(color: Color(0xFFB0AEC4))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Color(0xFFB0AEC4)))),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(colors: [Color(0xFFF716DC), Color(0xFFA41CF9)]),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                          child: const Text('Promover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmar != true) return;

                final promoted = await ApiService.promoteAdminUser(adminUserId: widget.adminUserId, targetUserId: widget.targetUserId);

                if (!mounted) return;

                if (promoted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Usuario promovido a administrador.')));
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al promover al usuario.')));
                }
              },
              tooltip: 'Promover a admin',
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFF716DC)),
            ),
          IconButton(
            onPressed: _eliminarUsuario,
            tooltip: 'Eliminar usuario',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1D8A), Color(0xFF16003A), Color(0xFF080010)],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF716DC))))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerCard(
                      '$nombre $apellido'.trim(),
                      (_usuario['foto_perfil'] ?? '').toString(),
                    ),
                    if (esAdmin && widget.targetUserId != widget.adminUserId) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF7C3AED)]),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C2FF).withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _delegarAEstudiante,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.person_remove_alt_1_rounded, color: Colors.white, size: 18),
                            label: Text(
                              'Delegar a Estudiante',
                              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _statChip('Racha', (_usuario['racha'] ?? 0).toString(), Icons.local_fire_department_rounded, const Color(0xFFF716DC)),
                        _statChip('Completadas', (_usuario['tareas_completadas'] ?? 0).toString(), Icons.task_alt_rounded, const Color(0xFF22C55E)),
                        _statChip('Horas', (_usuario['horas_estudio'] ?? 0).toString(), Icons.timer_rounded, const Color(0xFF00C2FF)),
                        _statChip('Objetivo', objetivo.isEmpty ? 'Sin objetivo' : objetivo, Icons.flag_rounded, const Color(0xFFA41CF9)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _sectionTitle('Planes de Estudio', Icons.assignment_rounded),
                    const SizedBox(height: 10),
                    if (_planes.isEmpty)
                      _emptyNotice('Sin planes registrados.')
                    else
                      ..._planes.map((plan) => _infoCard(
                            title: (plan['nombre'] ?? 'Plan').toString(),
                            subtitle: (plan['descripcion'] ?? '').toString(),
                            meta: 'Estado: ${(plan['estado'] ?? 'SIN ESTADO').toString()}',
                            accentColor: const Color(0xFF00C2FF),
                          )),
                    const SizedBox(height: 24),
                    _sectionTitle('Tareas', Icons.task_rounded),
                    const SizedBox(height: 10),
                    if (_tareas.isEmpty)
                      _emptyNotice('Sin tareas registradas.')
                    else
                      ..._tareas.map((tarea) => _infoCard(
                            title: (tarea['titulo'] ?? tarea['nombre'] ?? 'Tarea').toString(),
                            subtitle: (tarea['descripcion'] ?? '').toString(),
                            meta: 'Completada: ${((tarea['completada'] ?? false) == true) ? 'Sí' : 'No'}',
                            accentColor: const Color(0xFFF716DC),
                          )),
                    const SizedBox(height: 24),
                    _sectionTitle('Medallas', Icons.military_tech_rounded),
                    const SizedBox(height: 10),
                    if (_medallas.isEmpty)
                      _emptyNotice('Sin medallas.')
                    else
                      ..._medallas.map((medalla) => _infoCard(
                            title: (medalla['nombre'] ?? 'Medalla').toString(),
                            subtitle: (medalla['descripcion'] ?? '').toString(),
                            meta: 'Puntos: ${(medalla['puntos'] ?? 0).toString()}',
                            accentColor: Colors.amberAccent,
                          )),
                    const SizedBox(height: 24),
                    _sectionTitle('Horarios', Icons.schedule_rounded),
                    const SizedBox(height: 10),
                    if (_horarios.isEmpty)
                      _emptyNotice('Sin horarios configurados.')
                    else
                      ..._horarios.map((horario) => _infoCard(
                            title: (horario['dia'] ?? 'Horario').toString(),
                            subtitle: '${(horario['hora_inicio'] ?? '').toString()} - ${(horario['hora_fin'] ?? '').toString()}',
                            meta: 'Horario del estudiante',
                            accentColor: const Color(0xFF7C3AED),
                          )),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _headerCard(String nombre, String fotoPerfil) {
    Widget avatarChild = Text(
      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
      style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
    );

    if (fotoPerfil.trim().isNotEmpty) {
      try {
        final foto = fotoPerfil.trim();
        avatarChild = foto.startsWith('http')
            ? Image.network(foto, width: 64, height: 64, fit: BoxFit.cover)
            : Image.memory(base64Decode(foto.contains(',') ? foto.split(',').last : foto), width: 64, height: 64, fit: BoxFit.cover);
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E142C).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A2A68).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF716DC).withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF716DC), width: 2),
            ),
            child: ClipOval(
              child: SizedBox(
                width: 58,
                height: 58,
                child: ColoredBox(
                  color: const Color(0xFF16003A),
                  child: Center(child: avatarChild),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Registro: ${(_usuario['fecha_registro'] ?? 'Sin fecha').toString().split('T')[0]}',
                  style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF716DC), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E142C).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text('$label: ', style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 11)),
          Text(
            value,
            style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _emptyNotice(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 11),
      ),
    );
  }

  Widget _infoCard({required String title, required String subtitle, required String meta, required Color accentColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E142C).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A2A68).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFB0AEC4), fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              meta,
              style: GoogleFonts.orbitron(color: accentColor, fontWeight: FontWeight.w600, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}