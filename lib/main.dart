import 'package:material_ui/material_ui.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const FinanceControlApp());
}

// Raiz do app: define o tema e qual é a primeira tela
class FinanceControlApp extends StatelessWidget {
  const FinanceControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'financeControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const LoginScreen(),
    );
  }
}