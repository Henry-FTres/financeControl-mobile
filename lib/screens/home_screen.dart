import 'package:material_ui/material_ui.dart';

// Provisória: a home de verdade vem no próximo passo
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Login feito! A home vem no próximo passo.')),
    );
  }
}