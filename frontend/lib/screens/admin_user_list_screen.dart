import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'admin_user_detail_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  final String userId;
  const AdminUserListScreen({super.key, required this.userId});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.adminListUsers(widget.userId, search: _search);
    if (mounted) setState(() { _users = data?['usuarios'] ?? []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(title: Text('Usuarios', style: GoogleFonts.orbitron()), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) { _search = v; },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Buscar por nombre o correo', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF1F1A3A)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF44AA)), child: const Text('Buscar'))
            ]),
          ),
          Expanded(
            child: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF44AA))) : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, i) {
                final u = _users[i];
                final nombre = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}';
                return ListTile(
                  leading: CircleAvatar(backgroundImage: u['foto_perfil'] != null ? NetworkImage(u['foto_perfil']) : null, backgroundColor: const Color(0xFF2E1B4E), child: u['foto_perfil'] == null ? const Icon(Icons.person) : null),
                  title: Text(nombre, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(u['correo'] ?? '', style: const TextStyle(color: Colors.white38)),
                  trailing: IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserDetailScreen(requesterId: widget.userId, targetId: u['id']))).then((_) => _load())),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
