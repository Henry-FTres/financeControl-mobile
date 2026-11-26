import 'package:material_ui/material_ui.dart';

import '../services/api.dart';
import 'home_screen.dart';

// Tela de login
class LoginScreen extends StatefulWidget { // porque a tela precisa mudar sozinha conforme o uso
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers: guardam o que o usuário digita em cada campo
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _carregando = false;
  String? _erro;

  // Faz o login e abre a home
  Future<void> _entrar() async { // chama login da api, se der certo, abre a home, se der errado, mostra o erro
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await login(_emailController.text.trim(), _senhaController.text);
      if (!mounted) return;

      // Troca o login pela home, sem permitir "voltar" para o login
      Navigator.of(context).pushReplacement( // funciona numa pilha. Em vez de empilhar a tela nova, remove a antiga e adiciona a nova, não permitindo voltar para a tela de login
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _erro = e is ApiException
            ? e.mensagem
            : 'Não foi possível conectar à API.';
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Libera os controllers quando a tela é destruída
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { // a arvore da tela de login. Roda na primeira vez, e denovo toda vez que um setState é chamado
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'financeControl',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entre para ver suas finanças',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _entrar(),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                // Botão de entrar, que vira uma bolinha girando enquanto espera
                FilledButton(
                  onPressed: _carregando ? null : _entrar,
                  child: _carregando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}