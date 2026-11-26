import 'package:material_ui/material_ui.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart'; 

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
      theme: temaClaro(), 
      darkTheme: temaEscuro(), 
      themeMode: ThemeMode.system, // usa o tema do sistema (claro ou escuro)
      home: const LoginScreen(), // sempre abre no login screen
    );
  }
}