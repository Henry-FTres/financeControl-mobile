import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'auth_storage.dart';

// Endereço da API. No emulador Android, "localhost" é o próprio emulador;
// 10.0.2.2 é o endereço do PC visto de dentro dele.
// [LOCAL] Endereço da API: localhost no Chrome, 10.0.2.2 no emulador Android
final String apiUrl =
    kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

// Erro vindo da API, com a mensagem pronta para mostrar na tela
class ApiException implements Exception {
  final String mensagem;
  final int status;
  ApiException(this.mensagem, this.status);

  @override
  String toString() => mensagem;
}

// A API devolve "message" como lista (erros de validação) ou como texto
String _mensagemDeErro(dynamic dados) {
  if (dados is Map && dados['message'] is List) {
    return (dados['message'] as List).first.toString();
  }
  if (dados is Map && dados['message'] != null) {
    return dados['message'].toString();
  }
  return 'Algo deu errado. Tente novamente.';
}

// Login (rota pública): se der certo, guarda o token
// [LOCAL] Login no app: POST /auth/login e guarda o token
Future<void> login(String email, String senha) async {
  final resposta = await http.post(
    Uri.parse('$apiUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': senha}),
  );

  final dados = jsonDecode(resposta.body);
  if (resposta.statusCode != 200) {
    throw ApiException(_mensagemDeErro(dados), resposta.statusCode);
  }
  await AuthStorage.salvarToken(dados['access_token']);
}

// Rotas privadas: GET (buscar) e POST (criar), sempre com o token
Future<dynamic> apiGet(String caminho) => _enviar('GET', caminho);

Future<dynamic> apiPost(String caminho, Map<String, dynamic> corpo) =>
    _enviar('POST', caminho, corpo);

// [LOCAL] Envio das requisições privadas (GET/POST) com o token; 401 apaga o token
Future<dynamic> _enviar(String metodo, String caminho,
    [Map<String, dynamic>? corpo]) async { // não serve para login, pois login não tem token, e _enviar sempre manda token
  final token = await AuthStorage.lerToken();
  final url = Uri.parse('$apiUrl$caminho');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final resposta = metodo == 'GET'
      ? await http.get(url, headers: headers)
      : await http.post(url, headers: headers, body: jsonEncode(corpo));

  // Token expirado ou inválido: apaga e avisa a tela para voltar ao login
  if (resposta.statusCode == 401) {
    await AuthStorage.apagarToken();
    throw ApiException('Sua sessão expirou. Entre novamente.', 401);
  } // token expirado para user que ja estava logado, diferente de user não autenticado ainda, que significa email ou senha errados, que é tratado no login

  final dados = resposta.body.isEmpty ? null : jsonDecode(resposta.body);
  if (resposta.statusCode >= 400) {
    throw ApiException(_mensagemDeErro(dados), resposta.statusCode);
  }
  return dados;
}