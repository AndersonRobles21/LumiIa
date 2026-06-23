import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  // Base URL apuntando limpiamente a tus rutas locales de Node.js
  static const String baseUrl = 'http://localhost:3000/api/auth';

  /*
  ============================
  GET PROFILE
  ============================
  */
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
      );

      if (response.statusCode != 200) {
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Error en ApiService getProfile: $e');
      return null;
    }
  }

  /*
  ============================
  UPDATE PROFILE (Acoplado a perfiles_estudio y horarios)
  ============================
  */
  static Future<Map<String, dynamic>?> updateProfile({
    required String userId,
    required String nombre,
    required String apellido,
    required int horasDisponibles,
    required String objetivo,
    required int nivelProcrastinacion,
    String? fotoPerfil, // Nuevo campo
    List<Map<String, dynamic>>? horario,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'horas_disponibles': horasDisponibles,
          'objetivo': objetivo,
          'nivel_procrastinacion': nivelProcrastinacion,
          'foto_perfil': fotoPerfil, // Enviado al Node
          'horario': horario,
        }),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }
  /*
  ============================
  REQUEST PASSWORD RESET
  ============================
  */
  static Future<Map<String, dynamic>?> requestPasswordReset(String correo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );

      if (response.statusCode != 200) return null;
      return jsonDecode(response.body);
    } catch (e) {
      return null;
    }
  }

  /*
  ============================
  RESET PASSWORD
  ============================
  */
  static Future<bool> resetPassword(String correo, String password, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'password': password,
          'code': code,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /*
  ============================
  LOGIN (Sincronizado con tu backend por ID/UUID)
  ============================
  */
  static Future<Map<String, dynamic>> login({
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
        }),
      );

      if (response.body.isEmpty) {
        throw Exception('El servidor Node.js devolvió una respuesta vacía en el inicio de sesión.');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['mensaje'] ?? 'Error al iniciar sesión en el servidor local.',
        );
      }

      return data;
    } catch (e) {
      throw Exception('Error en ApiService login: $e');
    }
  }

  /*
  ============================
  REGISTER (Blindado Defensivamente)
  ============================
  */
  static Future<bool> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.body.isEmpty) {
        throw Exception('El servidor Node.js devolvió una respuesta vacía.');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode != 201) {
        throw Exception(
          data != null && data['mensaje'] != null 
              ? data['mensaje'] 
              : 'Error al registrar usuario en el servidor.',
        );
      }

      return true;
    } on FormatException catch (_) {
      throw Exception('Respuesta inválida del servidor (No se pudo procesar el JSON).');
    } catch (e) {
      rethrow;
    }
  }
}