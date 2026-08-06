import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import 'admin_user_list_screen.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  final String userId;
  const AdminPanelScreen({super.key, required this.userId});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _loading = true;
  Map<String, dynamic>? _overview;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _loading = true);
    final data = await ApiService.adminOverview(widget.userId);
    if (mounted) setState(() { _overview = data; _loading = false; });
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tendrás que volver a iniciar sesión para acceder a tu cuenta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Error cerrando sesión: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Panel de Administración', style: GoogleFonts.orbitron()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF44AA)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statCard('Usuarios', _overview?['total_users']?.toString() ?? '0'),
                      _statCard('Activos 30d', _overview?['users_active_30d']?.toString() ?? '0'),
                      _statCard('Tareas', _overview?['total_tareas']?.toString() ?? '0'),
                      _statCard('Completadas', _overview?['tareas_completadas']?.toString() ?? '0'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Promedio de rachas: ${_overview?['promedio_rachas']?.toStringAsFixed(2) ?? '0'}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserListScreen(userId: widget.userId))),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF44AA)),
                    child: Text('Gestionar usuarios', style: GoogleFonts.orbitron()),
                  )
                ],
              ),
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1A3A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
