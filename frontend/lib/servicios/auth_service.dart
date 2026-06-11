import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api/auth';

  static Future<Map<String, dynamic>> registrar({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/register');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10)); // ← timeout crítico

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return {'exito': true, 'datos': data};
      } else {
        return {'exito': false, 'error': data['error'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'exito': false, 'error': 'Sin respuesta del servidor: $e'};
    }
  }
}