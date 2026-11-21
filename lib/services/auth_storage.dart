import 'package:shared_preferences/shared_preferences.dart';

// Guarda, lê e apaga o token JWT no celular (equivalente ao localStorage da web)
class AuthStorage {
  static const _chave = 'fc_token';

  static Future<void> salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, token);
  }

  static Future<String?> lerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chave);
  }

  static Future<void> apagarToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}