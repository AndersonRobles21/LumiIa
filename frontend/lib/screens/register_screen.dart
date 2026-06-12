import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Conexión oficial con el puente unificado de Andrey
import 'package:frontend/services/api_service.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- CONTROLADORES DE TEXTO ---
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // --- CORRECCIÓN 1: Inicializado por defecto en 'POMODORO' ---
  String _metodoEstudioSeleccionado = 'POMODORO';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false; 

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DE ENVÍO REAL AL BACKEND ---
  void _crearCuenta() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // El mapa estructurado con los cambios quirúrgicos requeridos
      final Map<String, dynamic> userData = {
        "nombre": _nombreController.text.trim(),
        // --- CORRECCIÓN 4: Si va vacío, envía null limpito al backend ---
        "apellido": _apellidoController.text.trim().isEmpty
            ? null
            : _apellidoController.text.trim(),
        "correo": _emailController.text.trim(),
        "password": _passwordController.text,
        "metodo_estudio": _metodoEstudioSeleccionado,
      };

      try {
        // Enlace directo al puente oficial sin simulaciones
        bool success = await ApiService.register(userData);
        
        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Cuenta creada con éxito!', style: GoogleFonts.orbitron()),
              backgroundColor: const Color(0xFF102CE4),
            ),
          );
          Navigator.pop(context); // Regresa al Login de inmediato
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: GoogleFonts.orbitron()),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
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
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36.0,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      
                      Center(
                        child: Text(
                          'Registra tu cuenta',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      // --- FILA HORIZONTAL: NOMBRE Y APELLIDO ---
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Nombre'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nombreController,
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                                  decoration: _buildInputDecoration('Tu nombre'),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Nombre obligatorio' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Apellido'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _apellidoController,
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                                  decoration: _buildInputDecoration('Tu apellido'),
                                  // --- CORRECCIÓN 3: El apellido ya no es obligatorio ---
                                  validator: (value) {
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // --- EMAIL ---
                      _buildInputLabel('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration('Ingresa tu email@'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Correo obligatorio';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Introduce un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // --- DROPDOWN: MÉTODO DE ESTUDIO ---
                      _buildInputLabel('Método de Estudio'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _metodoEstudioSeleccionado,
                        dropdownColor: const Color(0xFF16003A),
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF102CE4)),
                        decoration: _buildInputDecoration('Selecciona un método'),
                        items: const [
                          DropdownMenuItem(value: 'POMODORO', child: Text('POMODORO')),
                          DropdownMenuItem(value: 'FEYNMAN', child: Text('FEYNMAN')),
                          DropdownMenuItem(value: 'ACTIVE_RECALL', child: Text('ACTIVE RECALL')),
                          DropdownMenuItem(value: 'MAPA_MENTAL', child: Text('MAPA MENTAL')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _metodoEstudioSeleccionado = value!;
                          });
                        },
                        // --- CORRECCIÓN 2: Eliminado el validador estricto del Dropdown ---
                      ),
                      const SizedBox(height: 18),

                      // --- CONTRASEÑA ---
                      _buildInputLabel('Contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration('Ingresa una contraseña').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.lock_outline : Icons.lock_open,
                              color: const Color(0xFF102CE4).withValues(alpha: 0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Contraseña obligatoria';
                          if (value.length < 6) return 'Contraseña mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // --- CONFIRMAR CONTRASEÑA ---
                      _buildInputLabel('Confirma tu contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration('Repite la contraseña').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.lock_outline : Icons.lock_open,
                              color: const Color(0xFF102CE4).withValues(alpha: 0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Por favor, confirma tu contraseña';
                          if (value != _passwordController.text) return 'Confirmar contraseña debe coincidir';
                          return null;
                        },
                      ),
                      const SizedBox(height: 35),

                      // --- BOTÓN CREAR CUENTA ---
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF716DC), Color(0xFFA41CF9)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _crearCuenta, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Crear cuenta',
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- TEXTO INFERIOR ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Listo para iniciar ',
                            style: GoogleFonts.orbitron(color: Colors.grey, fontSize: 12),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'continua',
                              style: GoogleFonts.orbitron(
                                color: const Color(0xFF102CE4),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helpers de estilos visuales unificados
  Widget _buildInputLabel(String labelText) {
    return Text(
      labelText,
      style: GoogleFonts.orbitron(
        color: const Color(0xFFE2E0EE),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.orbitron(color: Colors.grey[600], fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF301642).withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF321438), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF102CE4), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      errorStyle: GoogleFonts.orbitron(color: Colors.redAccent, fontSize: 11),
    );
  }
}