import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'admin_usuario_detalle_screen.dart';
import '../theme/app_theme.dart';

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
  List<dynamic> _usuariosFiltrados = [];
  String? _error;
  String _order = 'recent'; // 'recent' or 'az'
  final TextEditingController _searchController = TextEditingController();


  final List<Color> _cardColors = const [
    Color(0xFF1E142C), // Morado oscuro base
    Color(0xFF16003A), // Violeta profundo
    Color(0xFF0F1D8A), // Azul espacial intenso
    Color(0xFF4A154B), // Púrpura neón apagado
    Color(0xFF1B1464), // Azul nocturno elegante
    Color(0xFF3B0764), // Morado berenjena eléctrico
    Color(0xFF0C2D48), // Azul cobalto profundo
    Color(0xFF581C87), // Púrpura brillante vibrante
  ];

  @override
  void initState() {
    super.initState();
    _loadList();
    _searchController.addListener(_filtrarUsuarios);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _usuariosFiltrados = list;
        _loading = false;
      });
      _filtrarUsuarios();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _filtrarUsuarios() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _usuariosFiltrados = _usuarios;
      } else {
        _usuariosFiltrados = _usuarios.where((u) {
          final nombre = (u['nombre'] ?? '').toString().toLowerCase();
          final apellido = (u['apellido'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          return nombre.contains(query) || apellido.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tituloPanel = widget.onlyAdmins ? 'Panel de Administradores' : 'Panel de Estudiantes';

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: LumiAppTheme.surface(context),
        elevation: 0,
        title: Text(
          widget.onlyAdmins ? 'Administradores' : 'Estudiantes',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF0F1D8A), Color(0xFF16003A), Color(0xFF080010)]
              : const [Color(0xFFF8F5FC), Color(0xFFF0E4F8), Color(0xFFF8F5FC)],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF716DC), strokeWidth: 3))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- BANNER SUPERIOR INFORMATIVO ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: LumiAppTheme.surface(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: LumiAppTheme.outline(context)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF716DC).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.dashboard_rounded, color: Color(0xFFF716DC), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tituloPanel,
                                    style: GoogleFonts.orbitron(
                                      color: LumiAppTheme.primaryText(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Gestión y visualización de registros activos',
                                    style: GoogleFonts.orbitron(
                                      color: LumiAppTheme.secondaryText(context),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- BARRA DE BÚSQUEDA Y ORDENAMIENTO ---
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.orbitron(color: LumiAppTheme.primaryText(context), fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre o correo...',
                                hintStyle: GoogleFonts.orbitron(color: Colors.grey[600], fontSize: 12),
                                filled: true,
                                fillColor: LumiAppTheme.surface(context),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFB0AEC4), size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: const Color(0xFF4A2A68).withValues(alpha: 0.4)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFF716DC), width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          if (!widget.onlyAdmins) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E142C).withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF4A2A68).withValues(alpha: 0.4)),
                              ),
                              child: DropdownButton<String>(
                                value: _order,
                                dropdownColor: const Color(0xFF1E142C),
                                underline: const SizedBox.shrink(),
                                icon: const Icon(Icons.sort_rounded, color: Color(0xFFF716DC), size: 20),
                                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
                                items: [
                                  DropdownMenuItem(value: 'az', child: Text('A → Z', style: GoogleFonts.orbitron(fontSize: 12))),
                                  DropdownMenuItem(value: 'recent', child: Text('Recientes', style: GoogleFonts.orbitron(fontSize: 12))),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _order = v);
                                  _loadList(order: v);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A1B2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCC3355)),
                          ),
                          child: Text('Error: $_error', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12)),
                        ),

                      // --- CUADRÍCULA DE CARTAS MULTICOLOR ---
                      Expanded(
                        child: _usuariosFiltrados.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search_off_rounded, color: Color(0xFFB0AEC4), size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No se encontraron usuarios.',
                                      style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                                  
                                  return GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 0.82,
                                    ),
                                    itemCount: _usuariosFiltrados.length,
                                    itemBuilder: (context, index) {
                                      final usuario = _usuariosFiltrados[index] as Map<String, dynamic>;
                                      final nombre = (usuario['nombre'] ?? 'Usuario').toString();
                                      final apellido = (usuario['apellido'] ?? '').toString();
                                      final fecha = usuario['fecha_registro']?.toString().split('T')[0] ?? 'N/A';
                                      final foto = usuario['foto_perfil']?.toString();
                                      final id = (usuario['id'] ?? '').toString();

                                      // Asignar un color diferente a cada carta usando el índice de forma cíclica
                                      final cardColor = _cardColors[index % _cardColors.length];

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: id.isEmpty
                                            ? null
                                            : () async {
                                                final res = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => AdminUsuarioDetalleScreen(
                                                      adminUserId: widget.adminUserId,
                                                      targetUserId: id,
                                                    ),
                                                  ),
                                                );
                                                if (res == true) await _loadList();
                                              },
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            // Color de fondo dinámico inspirado en tu referencia de cartas
                                            color: cardColor.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: cardColor.withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Cabecera de la carta con indicador de rol
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.3),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      widget.onlyAdmins ? 'ADMIN' : 'STUDENT',
                                                      style: GoogleFonts.orbitron(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.auto_awesome_rounded,
                                                    size: 14,
                                                    color: Colors.white70,
                                                  ),
                                                ],
                                              ),

                                              // Avatar central estilo carta coleccionable
                                              Center(
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.3),
                                                        blurRadius: 8,
                                                      ),
                                                    ],
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 28,
                                                    backgroundColor: const Color(0xFF0B0813),
                                                    backgroundImage: foto != null ? NetworkImage(foto) : null,
                                                    child: foto == null
                                                        ? Text(
                                                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                                                            style: GoogleFonts.orbitron(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              ),

                                              // Información del usuario
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '$nombre $apellido'.trim(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.orbitron(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'Reg: $fecha',
                                                    style: GoogleFonts.orbitron(
                                                      color: Colors.white70,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}