import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String requesterId;
  final String targetId;
  const AdminUserDetailScreen({super.key, required this.requesterId, required this.targetId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.adminGetUser(widget.requesterId, widget.targetId);
    if (mounted) {
      _data = data;
      _nombreCtrl.text = data?['usuario']?['nombre'] ?? '';
      _apellidoCtrl.text = data?['usuario']?['apellido'] ?? '';
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final ok = await ApiService.adminUpdateUser(widget.requesterId, widget.targetId, {
      'nombre': _nombreCtrl.text,
      // Solo se permite modificar el nombre desde el admin
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario actualizado')));
      _editing = false;
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar')));
    }
  }

  void _startEdit() {
    setState(() {
      _editing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _nombreCtrl.text = _data?['usuario']?['nombre'] ?? '';
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar usuario? Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await ApiService.adminDeleteUser(widget.requesterId, widget.targetId);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = widget.requesterId != widget.targetId;
    final usuario = _data?['usuario'] ?? {};
    final perfil = _data?['perfil_estudio'] ?? {};
    final estadisticas = _data?['estadisticas'] ?? {};
    final pendientes = (_data?['tareas_pendientes'] ?? []).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        title: Text('Usuario', style: GoogleFonts.orbitron()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (canDelete)
            IconButton(icon: const Icon(Icons.delete), onPressed: _delete)
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.lock, color: Colors.white54),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF44AA)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: perfil['foto_perfil'] != null ? NetworkImage(perfil['foto_perfil']) : null,
                  backgroundColor: const Color(0xFF2E1B4E),
                  child: perfil['foto_perfil'] == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(height: 16),
                // Nombre: editable sólo tras pulsar editar
                _editing
                    ? Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _nombreCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Color(0xFF1F1A3A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745)), child: const Text('Guardar')),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: _cancelEdit, child: const Text('Cancelar')),
                      ])
                    : Row(children: [
                        Expanded(child: Text(_nombreCtrl.text.isNotEmpty ? _nombreCtrl.text : '-', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                        TextButton(onPressed: _startEdit, child: const Text('Editar')),
                      ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _apellidoCtrl,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white54),
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    labelStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF1F1A3A),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF44AA)), child: const Text('Guardar nombre')),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _infoTile('Correo', usuario['correo'] ?? '-'),
                      const SizedBox(height: 8),
                      _infoTile('Objetivo', perfil['objetivo'] ?? '-'),
                      const SizedBox(height: 8),
                      _infoTile('Días de racha', '${estadisticas['racha'] ?? 0}'),
                      const SizedBox(height: 8),
                      _infoTile('Tareas pendientes', '${pendientes.length}'),
                      const SizedBox(height: 16),
                      if (pendientes.isNotEmpty) ...[
                        const Text('Tareas pendientes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ...pendientes.map((t) => _taskCard(t)),
                      ] else ...[
                        const Text('No hay tareas pendientes.', style: TextStyle(color: Colors.white38)),
                      ],
                      const SizedBox(height: 16),
                      // Horarios
                      const Text('Horarios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if ((_data?['horarios'] ?? []).isNotEmpty) ...[
                        ...(_data?['horarios'] ?? []).map<Widget>((h) => _horarioCard(h)),
                      ] else ...[
                        const Text('No hay horarios registrados.', style: TextStyle(color: Colors.white38)),
                      ],
                      const SizedBox(height: 16),
                      // Planes y actividades
                      const Text('Planes de estudio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if ((_data?['planes_estudio'] ?? []).isNotEmpty) ...[
                        ...(_data?['planes_estudio'] ?? []).map<Widget>((p) => _planCard(p)),
                      ] else ...[
                        const Text('No hay planes de estudio.', style: TextStyle(color: Colors.white38)),
                      ],
                      if (!canDelete) ...[
                        const SizedBox(height: 16),
                        const Text('No puedes eliminar tu propio perfil.', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ]),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(task['nombre'] ?? 'Sin título', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(task['descripcion'] ?? '-', style: const TextStyle(color: Colors.white38)),
      ]),
    );
  }

  Widget _horarioCard(Map<String, dynamic> h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1F1A3A), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(h['dia'] ?? '-', style: const TextStyle(color: Colors.white)),
        Text('${h['hora_inicio'] ?? '-'} - ${h['hora_fin'] ?? '-'}', style: const TextStyle(color: Colors.white54)),
      ]),
    );
  }

  Widget _planCard(Map<String, dynamic> p) {
    final actividades = (_data?['actividades'] ?? []).where((a) => a['plan_id'] == p['id']).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1F1A3A), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p['nombre'] ?? 'Plan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(p['descripcion'] ?? '-', style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 8),
        if (actividades.isNotEmpty) ...[
          const Text('Actividades:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          ...actividades.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text('• ${a['titulo'] ?? a['titulo']}', style: const TextStyle(color: Colors.white38)),
              )),
        ] else ...[
          const Text('Sin actividades.', style: TextStyle(color: Colors.white38)),
        ],
      ]),
    );
  }
}
