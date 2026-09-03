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
          backgroundColor: const Color(0xFF111C4A),
          title: const Text('Editar nombre', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apellidoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Apellido', labelStyle: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
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
        const SnackBar(content: Text('Nombre actualizado correctamente.')),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el nombre.')),
      );
    }
  }

  Future<void> _eliminarUsuario() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111C4A),
        title: const Text('Eliminar usuario', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta acción elimina el perfil, planes, tareas y dependencias asociadas al usuario. ¿Continuar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
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
        const SnackBar(content: Text('Usuario eliminado correctamente.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el usuario.')),
      );
    }
  }

  Future<void> _delegarAEstudiante() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111C4A),
        title: const Text('Delegar administrador', style: TextStyle(color: Colors.white)),
        content: const Text(
          'El usuario volverá a ser estudiante. Se conservarán su perfil, foto, tareas, planes y progreso.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delegar')),
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
        const SnackBar(content: Text('Administrador delegado a estudiante.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo delegar el administrador.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (_usuario['nombre'] ?? 'Usuario').toString();
    final apellido = (_usuario['apellido'] ?? '').toString();
    final objetivo = (_usuario['objetivo'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFF080D2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C4A),
        foregroundColor: Colors.white,
        title: Text(
          (_usuario['es_admin'] ?? false) == true
              ? 'Detalle de administrador'
              : 'Detalle de estudiante',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _editarNombre,
            tooltip: 'Editar nombre',
            icon: const Icon(Icons.edit_note_rounded),
          ),
          if ((_usuario['es_admin'] ?? false) != true)
            IconButton(
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF111C4A),
                    title: const Text('Promover a administrador', style: TextStyle(color: Colors.white)),
                    content: const Text('¿Deseas promover este usuario a administrador?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Promover')),
                    ],
                  ),
                );

                if (confirmar != true) return;

                final promoted = await ApiService.promoteAdminUser(adminUserId: widget.adminUserId, targetUserId: widget.targetUserId);

                if (!mounted) return;

                if (promoted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario promovido a administrador.')));
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo promover al usuario.')));
                }
              },
              tooltip: 'Promover a admin',
              icon: const Icon(Icons.person_add_alt_1),
            ),
          IconButton(
            onPressed: _eliminarUsuario,
            tooltip: 'Eliminar usuario',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF44AA)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(
                    '$nombre ${apellido}'.trim(),
                    (_usuario['foto_perfil'] ?? '').toString(),
                  ),
                  if ((_usuario['es_admin'] ?? false) == true && widget.targetUserId != widget.adminUserId) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _delegarAEstudiante,
                        icon: const Icon(Icons.person_remove_alt_1),
                        label: const Text('Delegar a estudiante'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statChip('Racha', (_usuario['racha'] ?? 0).toString()),
                      _statChip('Tareas completadas', (_usuario['tareas_completadas'] ?? 0).toString()),
                      _statChip('Horas estudio', (_usuario['horas_estudio'] ?? 0).toString()),
                      _statChip('Objetivo', objetivo.isEmpty ? 'Sin objetivo' : objetivo),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Planes de estudio'),
                  if (_planes.isEmpty)
                    const Text('Sin planes registrados.', style: TextStyle(color: Colors.white70))
                  else
                    ..._planes.map((plan) => _infoCard(
                          title: (plan['nombre'] ?? 'Plan').toString(),
                          subtitle: (plan['descripcion'] ?? '').toString(),
                          meta: 'Estado: ${(plan['estado'] ?? 'SIN ESTADO').toString()}',
                        )),
                  const SizedBox(height: 20),
                  _sectionTitle('Tareas'),
                  if (_tareas.isEmpty)
                    const Text('Sin tareas registradas.', style: TextStyle(color: Colors.white70))
                  else
                    ..._tareas.map((tarea) => _infoCard(
                          title: (tarea['titulo'] ?? tarea['nombre'] ?? 'Tarea').toString(),
                          subtitle: (tarea['descripcion'] ?? '').toString(),
                          meta: 'Completada: ${((tarea['completada'] ?? false) == true) ? 'Sí' : 'No'}',
                        )),
                  const SizedBox(height: 20),
                  _sectionTitle('Medallas'),
                  if (_medallas.isEmpty)
                    const Text('Sin medallas.', style: TextStyle(color: Colors.white70))
                  else
                    ..._medallas.map((medalla) => _infoCard(
                          title: (medalla['nombre'] ?? 'Medalla').toString(),
                          subtitle: (medalla['descripcion'] ?? '').toString(),
                          meta: 'Puntos: ${(medalla['puntos'] ?? 0).toString()}',
                        )),
                  const SizedBox(height: 20),
                  _sectionTitle('Horarios'),
                  if (_horarios.isEmpty)
                    const Text('Sin horarios configurados.', style: TextStyle(color: Colors.white70))
                  else
                    ..._horarios.map((horario) => _infoCard(
                          title: (horario['dia'] ?? 'Horario').toString(),
                          subtitle: '${(horario['hora_inicio'] ?? '').toString()} - ${(horario['hora_fin'] ?? '').toString()}',
                          meta: 'Horario del estudiante',
                        )),
                ],
              ),
            ),
    );
  }

  Widget _headerCard(String nombre, String fotoPerfil) {
    Widget avatar = Text(
      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    );

    if (fotoPerfil.trim().isNotEmpty) {
      try {
        final foto = fotoPerfil.trim();
        avatar = foto.startsWith('http')
            ? Image.network(foto, width: 56, height: 56, fit: BoxFit.cover)
            : Image.memory(base64Decode(foto.contains(',') ? foto.split(',').last : foto), width: 56, height: 56, fit: BoxFit.cover);
      } catch (_) {
        // Se mantiene la inicial si la imagen almacenada no es válida.
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF18275E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3D5AFE).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFFF44AA),
            child: avatar,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registro: ${(_usuario['fecha_registro'] ?? 'Sin fecha').toString()}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.orbitron(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141B39),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required String subtitle, required String meta}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C4A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ],
          const SizedBox(height: 8),
          Text(meta, style: TextStyle(color: const Color(0xFF7C9CFF), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
