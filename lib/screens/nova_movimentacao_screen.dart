import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../services/api.dart';

// Lê o valor digitado e devolve um número. Aceita "12,50", "12.50" e "1.234,56".
// Com vírgula: a vírgula é o decimal e os pontos são milhar.
// Sem vírgula: o ponto é o decimal.
double? _lerValor(String texto) {
  var limpo = texto.trim();
  if (limpo.contains(',')) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(limpo);
}

// Tela para cadastrar uma movimentação (entrada ou saída)
// Ao salvar, volta para a tela anterior avisando "true" (salvou).
class NovaMovimentacaoScreen extends StatefulWidget {
  const NovaMovimentacaoScreen({super.key});

  @override
  State<NovaMovimentacaoScreen> createState() => _NovaMovimentacaoScreenState();
}

class _NovaMovimentacaoScreenState extends State<NovaMovimentacaoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _valorController = TextEditingController();
  final _quemController = TextEditingController();
  final _descricaoController = TextEditingController();

  String _tipo = 'SAIDA'; // 'SAIDA' ou 'ENTRADA'
  DateTime _data = DateTime.now(); // começa com hoje
  int? _contaId; // conta escolhida
  int? _categoriaId; // null = sem categoria
  bool _fixa = false;

  List<dynamic> _contas = [];
  List<dynamic> _categorias = [];

  bool _carregando = true; // buscando contas e categorias
  bool _salvando = false; // enviando para a API
  String? _erro;

  // O que roda quando a tela abre e quando fecha
  @override
  void initState() {
    super.initState();
    _carregarListas();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _quemController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // Busca as contas e as categorias para as caixas de escolha
  Future<void> _carregarListas() async {
    try {
      final respostas = await Future.wait([
        apiGet('/accounts'),
        apiGet('/categories'),
      ]);
      if (!mounted) return;

      setState(() {
        _contas = respostas[0] as List;
        _categorias = respostas[1] as List;
        // já deixa a primeira conta escolhida
        if (_contas.isNotEmpty) _contaId = _contas.first['id'] as int;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e is ApiException ? e.mensagem : 'Não foi possível conectar à API.';
        _carregando = false;
      });
    }
  }

  // Abre o calendário e guarda o dia escolhido
  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  // Valida os campos e envia para a API (que atualiza o saldo da conta)
  Future<void> _salvar() async {
    // roda o "validator" de cada campo; se algum devolver erro, para aqui
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final descricao = _descricaoController.text.trim();

    try {
      await apiPost('/transactions', {
        'transactionType': _tipo,
        'amount': _lerValor(_valorController.text),
        'date': DateFormat('yyyy-MM-dd').format(_data), // formato que a API espera
        'counterparty': _quemController.text.trim(),
        'accountId': _contaId,
        'fixed': _fixa,
        // campos opcionais: só vão se foram preenchidos
        if (_categoriaId != null) 'categoryId': _categoriaId,
        if (descricao.isNotEmpty) 'description': descricao,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true); // volta para a home avisando que salvou
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e is ApiException ? e.mensagem : 'Não foi possível conectar à API.';
        _salvando = false;
      });
    }
  }

  // Escolhe o que mostrar (carregando, sem contas ou o formulário)
  @override
  Widget build(BuildContext context) {
    Widget conteudo;

    if (_carregando) {
      // ainda buscando as listas: bolinha girando
      conteudo = const Center(child: CircularProgressIndicator());
    } else if (_contas.isEmpty) {
      // sem contas (ou erro ao buscar): não dá para lançar nada
      conteudo = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _erro ?? 'Cadastre uma conta primeiro: toda movimentação pertence a uma conta.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      conteudo = _formulario();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nova movimentação')), // já vem com a seta de voltar
      body: conteudo,
    );
  }

  // Todos os campos do formulário, um embaixo do outro
  Widget _formulario() {
    final saida = _tipo == 'SAIDA';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'SAIDA', label: Text('Saída'), icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: 'ENTRADA', label: Text('Entrada'), icon: Icon(Icons.arrow_downward)),
            ],
            selected: {_tipo},
            onSelectionChanged: (escolha) => setState(() => _tipo = escolha.first),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _valorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
              hintText: '0,00',
              border: OutlineInputBorder(),
            ),
            // Valor maior que zero e até 2 casas
            validator: (texto) {
              final valor = _lerValor(texto ?? '');
              if (valor == null || valor <= 0) return 'Informe um valor maior que zero';
              // a API aceita no máximo 2 casas decimais (centavos)
              if (valor != double.parse(valor.toStringAsFixed(2))) {
                return 'Use no máximo 2 casas decimais';
              }
              return null; // null = campo válido
            },
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: _escolherData,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('dd/MM/yyyy').format(_data)),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _quemController,
            decoration: InputDecoration(
              labelText: saida ? 'Pago para' : 'Recebido de',
              hintText: saida ? 'Ex.: Mercado, aluguel' : 'Ex.: salário, cliente',
              border: const OutlineInputBorder(),
            ),
            validator: (texto) {
              if (texto == null || texto.trim().isEmpty) {
                return saida ? 'Para quem foi o pagamento?' : 'De quem veio o dinheiro?';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            initialValue: _contaId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Conta', border: OutlineInputBorder()),
            items: [
              for (final c in _contas)
                DropdownMenuItem(
                  value: c['id'] as int,
                  child: Text('${c['institution']} · ${c['accountNumber']}'),
                ),
            ],
            onChanged: (id) => setState(() => _contaId = id),
            validator: (id) => id == null ? 'Escolha a conta' : null,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int?>(
            initialValue: _categoriaId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoria (opcional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Sem categoria')),
              for (final c in _categorias)
                DropdownMenuItem<int?>(value: c['id'] as int, child: Text(c['name'] as String)),
            ],
            onChanged: (id) => setState(() => _categoriaId = id),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descricaoController,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Movimentação fixa'),
            subtitle: const Text('Se repete todo mês, como aluguel ou salário'),
            value: _fixa,
            onChanged: (valor) => setState(() => _fixa = valor),
          ),

          if (_erro != null) ...[
            const SizedBox(height: 8),
            Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(saida ? 'Registrar saída' : 'Registrar entrada'),
          ),
        ],
      ),
    );
  }
}