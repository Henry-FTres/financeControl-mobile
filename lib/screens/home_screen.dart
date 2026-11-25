import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../services/api.dart';
import '../services/auth_storage.dart';
import 'login_screen.dart';
import 'nova_movimentacao_screen.dart';
// Formata 1234.5 como "R$ 1.234,50"
// formatador pronto
final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

// A API manda os valores como texto ("150.00"); converte para número
// transforma de dynamic para double, mesmo que seja String ou int
double _numero(dynamic valor) => double.parse(valor.toString());

// [LOCAL] Tela home do app: saldo, resumo do mês e últimas movimentações
class HomeScreen extends StatefulWidget { // é descartável, não precisa de parâmetros
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState(); // cria o objeto que guarda os dados da tela
}

class _HomeScreenState extends State<HomeScreen> { // é onde os dados da tela são carregados e exibidos
  bool _carregando = true;
  String? _erro;

  String _nome = '';
  double _saldoTotal = 0;
  double _entradasMes = 0;
  double _saidasMes = 0;
  List<dynamic> _recentes = [];

  // Roda uma vez, quando a tela é criada
  @override
  void initState() { // é chamado antes de build, só uma vez, que busca os dados da API
    super.initState();
    _carregar();
  }

  // [LOCAL] Busca os dados da home: GET /users/me, /accounts e /transactions; calcula o mês
  Future<void> _carregar() async { // future é o tipo de dado que vai demorar para chegar, async define que a função é assíncrona e o await espera ele chegar
    try {
      // Faz as três requisições ao mesmo tempo e espera todas
      final respostas = await Future.wait([ // await Future.wait: espera todas as requisições terminarem, e retorna uma lista com as respostas
        apiGet('/users/me'),
        apiGet('/accounts'),
        apiGet('/transactions'),
      ]);
      if (!mounted) return; // verifica se o usuario saiu da tela antes de terminar a requisição, se sim, não atualiza a tela

      final usuario = respostas[0];
      final contas = respostas[1] as List;
      final movimentacoes = respostas[2] as List;

      // Percorre movimentações do mes atual, somando entradas e saidas. API não faz isso por conta
      final hoje = DateTime.now();
      double entradas = 0;
      double saidas = 0;
      for (final m in movimentacoes) {
        final data = DateTime.parse(m['date']);
        if (data.year != hoje.year || data.month != hoje.month) continue;

        if (m['transactionType'] == 'ENTRADA') {
          entradas += _numero(m['amount']);
        } else {
          saidas += _numero(m['amount']);
        }
      }

      setState(() {
        _nome = (usuario['name'] as String).split(' ').first; // Pra aparecer "Olá, usuário"
        _saldoTotal = contas.fold(0.0, (soma, c) => soma + _numero(c['balance'])); // uma list comprehension que soma todos os saldos das contas
        _entradasMes = entradas;
        _saidasMes = saidas;
        _recentes = movimentacoes.take(5).toList(); // pega as 5 primeiras movimentações da lista, da mais nova pra mais antiga
        _erro = null;
        _carregando = false;
      });
    } on ApiException catch (e) { // api respondeu, mas com erro
      if (e.status == 401) return _irParaLogin(); // token expirou
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    } catch (_) { // api nem chegou a responder, ou deu algum outro erro
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível conectar à API.';
        _carregando = false;
      });
    }
  }

  void _irParaLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // abre a tela de nova movimentação e, se salvou, recarrega os números
  // [LOCAL] Ação do botão "Nova movimentação": abre a tela e recarrega a home se salvou
  Future<void> _novaMovimentacao() async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NovaMovimentacaoScreen()),
    );
    if (salvou != true || !mounted) return; // voltou sem salvar, ou saiu da tela

    _carregar(); // busca tudo de novo: saldo, entradas, saídas e lista
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Movimentação registrada')),
    );
  }

  // [LOCAL] Ação do botão "Sair"
  Future<void> _sair() async { // apaga o token do celular e volta para a tela de login
    await AuthStorage.apagarToken();
    _irParaLogin();
  }

  @override
  Widget build(BuildContext context) { // desenha a tela. Roda na primeira vez, e denovo toda vez que um setState é chamado
    return Scaffold(
      appBar: AppBar(
        title: Text(_nome.isEmpty ? 'financeControl' : 'Olá, $_nome'),
        actions: [ // barra inferior da tela, com o botão de sair
          // [LOCAL] Botão "Sair" (ícone no canto superior direito da barra do topo)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _sair,
          ),
        ],
      ),
      body: _conteudo(), // chama o método que escolhe o que mostrar: carregando, erro ou os dados
      // botão flutuante no canto de baixo para lançar uma movimentação
      // [LOCAL] Botão flutuante "Nova movimentação" (canto inferior direito)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaMovimentacao,
        icon: const Icon(Icons.add),
        label: const Text('Nova movimentação'),
      ),
    );
  }

  // Escolhe o que mostrar no meio da tela, conforme o estado: carregando, erro ou dados
  Widget _conteudo() {
    // ainda esperando a API: mostra a bolinha girando
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    // deu erro: mostra a mensagem e um botão para tentar de novo
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!),
            const SizedBox(height: 12),
            // [LOCAL] Botão "Tentar de novo" (aparece quando dá erro)
            FilledButton(
              onPressed: () {
                setState(() => _carregando = true);
                _carregar();
              },
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }

    // deu tudo certo: mostra os dados
    // RefreshIndicator é o puxar para baixo para atualizar, que chama _carregar de novo
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), // deixa puxar para atualizar mesmo quando a lista é curta
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // espaço embaixo para o botão flutuante não cobrir a lista
        children: [
          // [LOCAL] Card "Saldo total" (topo)
          _CardValor(titulo: 'Saldo total', valor: _saldoTotal, destaque: true),
          const SizedBox(height: 12),
          // [LOCAL] Cards "Entradas do mês" (verde) e "Saídas do mês" (vermelho), lado a lado
          Row(
            children: [
              Expanded(
                child: _CardValor(
                  titulo: 'Entradas do mês',
                  valor: _entradasMes,
                  cor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardValor(
                  titulo: 'Saídas do mês',
                  valor: _saidasMes,
                  cor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // [LOCAL] Lista "Últimas movimentações" (as 5 mais recentes)
          Text(
            'Últimas movimentações',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_recentes.isEmpty)
            const Text('Nada lançado ainda.')
          else
            ..._recentes.map((m) => _LinhaMovimentacao(movimentacao: m)),
        ],
      ),
    );
  }
}

// card reaproveitável: só exibe um título e um valor em dinheiro (Stateless: não muda sozinho)
// [LOCAL] Widget do card de valor (usado nos 3 cards da home)
class _CardValor extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color? cor;
  final bool destaque;

  const _CardValor({
    required this.titulo,
    required this.valor,
    this.cor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: estilos.bodyMedium),
            const SizedBox(height: 4),
            Text(
              _moeda.format(valor),
              style: (destaque ? estilos.headlineMedium : estilos.titleLarge)
                  ?.copyWith(color: cor),
            ),
          ],
        ),
      ),
    );
  }
}

// linha da lista: ícone, quem pagou/recebeu, data e valor (verde = entrada, vermelho = saída)
// [LOCAL] Widget de uma linha da lista de movimentações
class _LinhaMovimentacao extends StatelessWidget {
  final dynamic movimentacao;

  const _LinhaMovimentacao({required this.movimentacao});

  @override
  Widget build(BuildContext context) {
    final entrada = movimentacao['transactionType'] == 'ENTRADA';
    final cor = entrada ? Colors.green : Colors.red;
    final valor = _numero(movimentacao['amount']);
    final data = DateTime.parse(movimentacao['date']);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entrada ? Icons.arrow_downward : Icons.arrow_upward,
        color: cor,
      ),
      title: Text(movimentacao['counterparty']),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(data)),
      trailing: Text(
        '${entrada ? '+' : '-'} ${_moeda.format(valor)}',
        style: TextStyle(color: cor, fontWeight: FontWeight.w600),
      ),
    );
  }
}