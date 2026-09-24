import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'configuracion_screen.dart';
import 'app_bottom_navbar.dart';
import 'app_language.dart';
import 'edit_profile_screen.dart';
import 'schedule_setup_flow.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AppLanguageListenerMixin<ProfileScreen> {
  final _nameController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _objetivoController = TextEditingController();

  int _nivelProcrastinacion = 1;
  bool _isLoading = true;
  String get _userId => widget.userId;

  List<ScheduleSlot> _scheduleSlots = [];
  int _scheduleRevision = 0;

  File? _imageFile;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarDatosDeBaseDeDatos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apellidoController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  int? _parseServerMinutes(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  Future<void> _seleccionarNuevaImagen() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 250, // Reducido para que la resolución sea ligera
        maxHeight: 250, // Reducido para que la resolución sea ligera
        imageQuality:
            40, // Alta compresión para que pese muy pocos KB y no dé error 413
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        String base64String = base64Encode(bytes);

        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }

        setState(() {
          _imageFile = null;
          _base64Image = base64String;
        });
      }
    } catch (e) {
      _showSnackBar(
        tr('No se pudo acceder a la galería.', 'Could not access gallery.'),
      );
    }
  }

  Future<void> _cargarDatosDeBaseDeDatos() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getProfile(_userId);

    if (data != null) {
      final scheduleFromServer = <ScheduleSlot>[];

      if (data['perfil_estudio'] != null) {
        var fotoServidor = data['perfil_estudio']['foto_perfil'];

        // Limpiamos el Base64 por si en la BD se guardó con el header data:image/...
        if (fotoServidor != null && fotoServidor.toString().contains(',')) {
          fotoServidor = fotoServidor.toString().split(',').last;
        }

        _base64Image = fotoServidor;
        _objetivoController.text = data['perfil_estudio']['objetivo'] ?? '';
        _nivelProcrastinacion =
            data['perfil_estudio']['nivel_procrastinacion'] ?? 1;
      }

      if (data['horarios'] != null && data['horarios'] is List) {
        final List<dynamic> horarioServer = data['horarios'];
        for (final item in horarioServer) {
          if (item is Map<String, dynamic>) {
            final String dia = item['dia']?.toString() ?? '';
            final dayIndex = ScheduleDayMapper.indexForServerDay(dia);
            final inicio = _parseServerMinutes(
              item['hora_inicio']?.toString() ?? '',
            );
            final fin = _parseServerMinutes(item['hora_fin']?.toString() ?? '');
            if (dayIndex >= 0 &&
                inicio != null &&
                fin != null &&
                fin > inicio) {
              scheduleFromServer.add(
                ScheduleSlot(
                  dayKey: ScheduleDayMapper.keys[dayIndex],
                  startMinutes: inicio,
                  endMinutes: fin,
                ),
              );
            }
          }
        }
      }

      setState(() {
        _nameController.text = data['nombre'] ?? '';
        _apellidoController.text = data['apellido'] ?? '';
        _scheduleSlots = scheduleFromServer;
        _scheduleRevision++;
      });
    }
    setState(() => _isLoading = false);
  }

  Widget _buildAvatar() {
    Widget avatarChild = const Icon(
      Icons.person,
      size: 50,
      color: Colors.white30,
    );

    if (_imageFile != null) {
      // Prioridad 1: Imagen recién seleccionada desde el dispositivo (Archivo local)
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.file(
          _imageFile!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (_base64Image != null && _base64Image!.startsWith('asset:')) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.asset(
          _base64Image!.substring(6),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (_base64Image != null && _base64Image!.trim().isNotEmpty) {
      // Prioridad 2: Imagen convertida en Base64 proveniente de Supabase / Backend
      try {
        String cleanBase64 = _base64Image!.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }

        avatarChild = ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.memory(
            base64Decode(cleanBase64),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.white54,
              );
            },
          ),
        );
      } catch (e) {
        avatarChild = const Icon(Icons.person, size: 50, color: Colors.white30);
      }
    }

    final isDesktop = Responsive.esEscritorio(context);
    final avatarRadius = isDesktop ? 80.0 : 50.0;
    final imageSize = isDesktop ? 160.0 : 100.0;

    // Adjust inner avatar child sizes if image widgets are used
    if (_imageFile != null) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(avatarRadius),
        child: Image.file(
          _imageFile!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
        ),
      );
    } else if (_base64Image != null && _base64Image!.startsWith('asset:')) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(avatarRadius),
        child: Image.asset(
          _base64Image!.substring(6),
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
        ),
      );
    } else if (_base64Image != null &&
        _base64Image!.trim().isNotEmpty &&
        !_base64Image!.startsWith('asset:')) {
      try {
        String cleanBase64 = _base64Image!.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }

        avatarChild = ClipRRect(
          borderRadius: BorderRadius.circular(avatarRadius),
          child: Image.memory(
            base64Decode(cleanBase64),
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.broken_image,
                size: imageSize * 0.5,
                color: Colors.white54,
              );
            },
          ),
        );
      } catch (e) {
        avatarChild = Icon(
          Icons.person,
          size: avatarRadius * 0.6,
          color: Colors.white30,
        );
      }
    }

    return GestureDetector(
      onTap: _seleccionarNuevaImagen,
      child: Stack(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: const Color(0xFF2A1F5A),
            child: avatarChild,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 8 : 6),
              decoration: const BoxDecoration(
                color: Color(0xFFFF44AA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: isDesktop ? 18 : 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleSend(List<ScheduleSlot> scheduleSlots) async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar(
        tr('Por favor, ingresa tu nombre.', 'Please enter your name.'),
      );
      return false;
    }
    setState(() => _isLoading = true);
    final horarioParaBackend = scheduleSlots
        .map(
          (slot) => {
            'dia': ScheduleDayMapper.serverNameForKey(slot.dayKey),
            'hora_inicio': _formatMinutesForBackend(slot.startMinutes),
            'hora_fin': _formatMinutesForBackend(slot.endMinutes),
          },
        )
        .toList();
    final minutosDisponibles = scheduleSlots.fold<int>(
      0,
      (total, slot) => total + slot.endMinutes - slot.startMinutes,
    );
    final resultado = await ApiService.updateProfile(
      userId: _userId,
      nombre: _nameController.text.trim(),
      apellido: _apellidoController.text.trim(),
      horasDisponibles: (minutosDisponibles / 60).ceil(),
      objetivo: _objetivoController.text.trim(),
      nivelProcrastinacion: _nivelProcrastinacion,
      fotoPerfil: _base64Image,
      horario: horarioParaBackend,
    );
    setState(() => _isLoading = false);
    if (resultado != null) {
      setState(() {
        _scheduleSlots = List<ScheduleSlot>.from(scheduleSlots);
        _scheduleRevision++;
      });
      _showSnackBar(
        tr(
          resultado['reajuste_en_proceso'] == true
              ? 'Perfil guardado. Actualizando tus planes según tu nuevo horario...'
              : '¡Perfil y hábitos guardados correctamente!',
          resultado['reajuste_en_proceso'] == true
              ? 'Profile saved. Updating your plans for your new schedule...'
              : 'Profile and habits saved successfully!',
        ),
      );
      return true;
    } else {
      _showSnackBar(
        tr(
          'Error al intentar guardar cambios.',
          'Error trying to save changes.',
        ),
      );
      return false;
    }
  }

  String _formatMinutesForBackend(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
                    Color(0xFF0D0D2B),
                    Color(0xFF1A1040),
                    Color(0xFF0D0D2B),
                  ]
                : const [
                    Color(0xFFF8F5FC),
                    Color(0xFFF0E4F8),
                    Color(0xFFF8F5FC),
                  ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: Responsive.esEscritorio(context)
                      ? Responsive.anchoSidebar(context)
                      : 0,
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFCC00CC),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 16.0,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  tr('MI PERFIL', 'MY PROFILE'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Editar personaje',
                                        icon: const Icon(
                                          Icons.face_retouching_natural,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditProfileScreen(
                                                  userId: _userId,
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.settings,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ConfiguracionScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: Responsive.esEscritorio(context)
                                      ? 1100
                                      : 600,
                                ),
                                child: Builder(
                                  builder: (ctx) {
                                    final isDesktop = Responsive.esEscritorio(
                                      ctx,
                                    );
                                    if (isDesktop) {
                                      // Desktop: avatar and name on left, rest of profile on right
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Left column: avatar and basic name info
                                          Container(
                                            width: 300,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 8),
                                                _buildAvatar(),
                                                SizedBox(
                                                  height:
                                                      Responsive.espacio(ctx) *
                                                      1.5,
                                                ),
                                                Text(
                                                  tr('Nombre', 'First Name'),
                                                  style: TextStyle(
                                                    color:
                                                        LumiAppTheme.primaryText(
                                                          ctx,
                                                        ),
                                                    fontSize:
                                                        Responsive.tamanioTexto(
                                                          ctx,
                                                        ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height:
                                                      Responsive.espacio(ctx) /
                                                      2,
                                                ),
                                                _buildInputField(
                                                  _nameController,
                                                  tr(
                                                    'Ingresa tu nombre',
                                                    'Enter your first name',
                                                  ),
                                                ),
                                                SizedBox(
                                                  height:
                                                      Responsive.espacio(ctx) *
                                                      1.25,
                                                ),
                                                Text(
                                                  tr('Apellido', 'Last Name'),
                                                  style: TextStyle(
                                                    color:
                                                        LumiAppTheme.primaryText(
                                                          ctx,
                                                        ),
                                                    fontSize:
                                                        Responsive.tamanioTexto(
                                                          ctx,
                                                        ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height:
                                                      Responsive.espacio(ctx) /
                                                      2,
                                                ),
                                                _buildInputField(
                                                  _apellidoController,
                                                  tr(
                                                    'Ingresa tu apellido',
                                                    'Enter your last name',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 18),
                                          // Right column: rest of editable fields
                                          Expanded(
                                            child: SingleChildScrollView(
                                              padding: EdgeInsets.only(
                                                right:
                                                    Responsive.paddingHorizontalRecomendado(
                                                      ctx,
                                                    ),
                                                bottom: 90,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(height: 8),
                                                  Text(
                                                    tr(
                                                      'Objetivo de Estudio',
                                                      'Study Goal',
                                                    ),
                                                    style: TextStyle(
                                                      color:
                                                          LumiAppTheme.primaryText(
                                                            ctx,
                                                          ),
                                                      fontSize:
                                                          Responsive.tamanioSubtitulo(
                                                            ctx,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        Responsive.espacio(
                                                          ctx,
                                                        ) /
                                                        2,
                                                  ),
                                                  _buildInputField(
                                                    _objetivoController,
                                                    tr(
                                                      "Ej: Certificarme como programadora",
                                                      "Ex: Get certified as a developer",
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        Responsive.espacio(
                                                          ctx,
                                                        ) *
                                                        1.5,
                                                  ),

                                                  Text(
                                                    '${tr('Nivel de Procrastinación', 'Procrastination Level')}: $_nivelProcrastinacion',
                                                    style: TextStyle(
                                                      color:
                                                          LumiAppTheme.primaryText(
                                                            ctx,
                                                          ),
                                                      fontSize:
                                                          Responsive.tamanioSubtitulo(
                                                            ctx,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Slider(
                                                    value: _nivelProcrastinacion
                                                        .toDouble(),
                                                    min: 1,
                                                    max: 10,
                                                    divisions: 9,
                                                    activeColor: const Color(
                                                      0xFFFF44AA,
                                                    ),
                                                    inactiveColor: const Color(
                                                      0xFF1F1B2E,
                                                    ),
                                                    onChanged: (value) => setState(
                                                      () =>
                                                          _nivelProcrastinacion =
                                                              value.toInt(),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        Responsive.espacio(
                                                          ctx,
                                                        ) *
                                                        1.5,
                                                  ),

                                                  ScheduleSetupFlow(
                                                    key: ValueKey(
                                                      _scheduleRevision,
                                                    ),
                                                    initialSlots:
                                                        _scheduleSlots,
                                                    onSave: _handleSend,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    // Mobile / tablet: original column but responsive
                                    return SingleChildScrollView(
                                      padding: EdgeInsets.only(
                                        left:
                                            Responsive.paddingHorizontalRecomendado(
                                              ctx,
                                            ),
                                        right:
                                            Responsive.paddingHorizontalRecomendado(
                                              ctx,
                                            ),
                                        bottom: 90,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 8),
                                          Center(child: _buildAvatar()),
                                          SizedBox(
                                            height: Responsive.espacio(ctx) * 3,
                                          ),

                                          Text(
                                            tr('Nombre', 'First Name'),
                                            style: TextStyle(
                                              color: LumiAppTheme.primaryText(
                                                ctx,
                                              ),
                                              fontSize: Responsive.tamanioTexto(
                                                ctx,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                            height: Responsive.espacio(ctx) / 2,
                                          ),
                                          _buildInputField(
                                            _nameController,
                                            tr(
                                              'Ingresa tu nombre',
                                              'Enter your first name',
                                            ),
                                          ),
                                          SizedBox(
                                            height:
                                                Responsive.espacio(ctx) * 1.5,
                                          ),

                                          Text(
                                            tr('Apellido', 'Last Name'),
                                            style: TextStyle(
                                              color: LumiAppTheme.primaryText(
                                                ctx,
                                              ),
                                              fontSize: Responsive.tamanioTexto(
                                                ctx,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                            height: Responsive.espacio(ctx) / 2,
                                          ),
                                          _buildInputField(
                                            _apellidoController,
                                            tr(
                                              'Ingresa tu apellido',
                                              'Enter your last name',
                                            ),
                                          ),
                                          SizedBox(
                                            height:
                                                Responsive.espacio(ctx) * 1.5,
                                          ),

                                          Text(
                                            tr(
                                              'Objetivo de Estudio',
                                              'Study Goal',
                                            ),
                                            style: TextStyle(
                                              color: LumiAppTheme.primaryText(
                                                ctx,
                                              ),
                                              fontSize:
                                                  Responsive.tamanioSubtitulo(
                                                    ctx,
                                                  ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                            height: Responsive.espacio(ctx) / 2,
                                          ),
                                          _buildInputField(
                                            _objetivoController,
                                            tr(
                                              "Ej: Certificarme como programadora",
                                              "Ex: Get certified as a developer",
                                            ),
                                          ),
                                          SizedBox(
                                            height:
                                                Responsive.espacio(ctx) * 1.5,
                                          ),

                                          Text(
                                            '${tr('Nivel de Procrastinación', 'Procrastination Level')}: $_nivelProcrastinacion',
                                            style: TextStyle(
                                              color: LumiAppTheme.primaryText(
                                                ctx,
                                              ),
                                              fontSize:
                                                  Responsive.tamanioSubtitulo(
                                                    ctx,
                                                  ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Slider(
                                            value: _nivelProcrastinacion
                                                .toDouble(),
                                            min: 1,
                                            max: 10,
                                            divisions: 9,
                                            activeColor: const Color(
                                              0xFFFF44AA,
                                            ),
                                            inactiveColor: const Color(
                                              0xFF1F1B2E,
                                            ),
                                            onChanged: (value) => setState(
                                              () => _nivelProcrastinacion =
                                                  value.toInt(),
                                            ),
                                          ),

                                          SizedBox(
                                            height:
                                                Responsive.espacio(ctx) * 1.5,
                                          ),
                                          ScheduleSetupFlow(
                                            key: ValueKey(_scheduleRevision),
                                            initialSlots: _scheduleSlots,
                                            onSave: _handleSend,
                                          ),
                                          SizedBox(
                                            height: Responsive.espacio(ctx) * 3,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              AppBottomNavbar(userId: _userId, currentIndex: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: TextStyle(color: LumiAppTheme.primaryText(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: LumiAppTheme.secondaryText(context),
          fontSize: 14,
        ),
        filled: true,
        fillColor: LumiAppTheme.surface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF44AA), width: 1),
        ),
      ),
    );
  }
}
