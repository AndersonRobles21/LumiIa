import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'admin_usuario_detalle_screen.dart';

class AdminUsuariosListV2 extends StatefulWidget {
  final String adminUserId;
  final bool onlyAdmins;

  const AdminUsuariosListV2({super.key, required this.adminUserId, this.onlyAdmins = false});

  @override
  State<AdminUsuariosListV2> createState() => _AdminUsuariosListV2State();
}

class _AdminUsuariosListV2State extends State<AdminUsuariosListV2> {
  bool _loading = true;
  List<dynamic> _usuarios = [];
  String? _error;
  String _order = 'recent'; // 'recent' or 'az'

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList({String? order}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ord = order ?? _order;
      final list = widget.onlyAdmins
          ? await ApiService.getAdminAdministradores(widget.adminUserId)
          : await ApiService.getAdminUsuarios(widget.adminUserId, order: ord == 'az' ? 'az' : 'recent');

      if (!mounted) return;

      setState(() {
        _usuarios = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C4A),
        foregroundColor: Colors.white,
        title: Text(widget.onlyAdmins ? 'Administradores' : 'Estudiantes', style: GoogleFonts.orbitron(fontWeight: FontWeight.w700)),
        actions: [
          if (!widget.onlyAdmins)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<String>(
                value: _order,
                dropdownColor: const Color(0xFF111C4A),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'az', child: Text('A → Z')),
                  DropdownMenuItem(value: 'recent', child: Text('Últimos creados')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _order = v);
                  _loadList(order: v);
                },
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF44AA)))
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_error != null) Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                    Expanded(
                      child: _usuarios.isEmpty
                          ? const Center(child: Text('No hay usuarios para mostrar.', style: TextStyle(color: Colors.white70)))
                          : ListView.separated(
                              itemCount: _usuarios.length,
                              separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2F5A)),
                              itemBuilder: (context, index) {
                                final usuario = _usuarios[index] as Map<String, dynamic>;
                                final nombre = (usuario['nombre'] ?? 'Usuario').toString();
                                final apellido = (usuario['apellido'] ?? '').toString();
                                final fecha = usuario['fecha_registro']?.toString() ?? 'Sin fecha';
                                final foto = usuario['foto_perfil']?.toString();
                                final id = (usuario['id'] ?? '').toString();

                                return ListTile(
                                  onTap: id.isEmpty
                                      ? null
                                      : () async {
                                          final res = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AdminUsuarioDetalleScreen(adminUserId: widget.adminUserId, targetUserId: id),
                                            ),
                                          );
                                          if (res == true) await _loadList();
                                        },
                                  leading: foto != null
                                      ? CircleAvatar(backgroundImage: NetworkImage(foto))
                                      : CircleAvatar(backgroundColor: const Color(0xFFFF44AA), child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U')),
                                  title: Text('$nombre $apellido', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  subtitle: Text('Registrado: $fecha', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
