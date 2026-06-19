import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/auth';

  /*
  ============================
  GET PROFILE
  ============================
  */
  static Future<Map<String, dynamic>?> getProfile(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$userId'),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
  }

  /*
  ============================
  UPDATE PROFILE (Sincronizado con Node.js)
  ============================
  */
  static Future<Map<String, dynamic>?> updateProfile({
    required String userId,
    required String nombre,
    required String apellido,
    required String metodoEstudio,
    List<Map<String, String>>? horario, // Bloques de horas seleccionados
  }) async {
    try {
      // 1. Se cambió la URL para inyectar el ID como parámetro de ruta
      final url = Uri.parse('$baseUrl/profile/$userId'); 
      
      // 2. Se cambió el método a PUT para coincidir con router.put
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        // 3. Claves corregidas en formato snake_case según tu consulta SQL de Express
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'metodo_estudio': metodoEstudio, 
          'horario': horario, 
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error en la respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error en ApiService: $e');
      return null;
    }
  }

  /*
  ============================
  REQUEST PASSWORD RESET
  ============================
  */
  static Future<Map<String, dynamic>?> requestPasswordReset(
    String correo,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/request'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
  }

  /*
  ============================
  RESET PASSWORD
  ============================
  */
  static Future<bool> resetPassword(
    String correo,
    String password,
    String code,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/reset'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
        'code': code,
      }),
    );

    return response.statusCode == 200;
  }

  /*
  ============================
  LOGIN
  POST /api/auth/login
  ============================
  */
  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['mensaje'] ?? 'Error al iniciar sesión',
      );
    }

    return data;
  }

  /*
  ============================
  REGISTER
  POST /api/auth/register
  ============================
  */
  static Future<bool> register(
    Map<String, dynamic> userData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['mensaje'] ?? 'Error al registrar usuario',
      );
    }

    return true;
  }
}