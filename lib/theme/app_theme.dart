import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

class FcCores {
  final Color surface100, surface200, surface300;
  final Color line, lineStrong, ink, inkMuted;
  final Color brand, brandInk, brandSoft, saida, saidaSoft;

  const FcCores({
    required this.surface100,
    required this.surface200,
    required this.surface300,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.brand,
    required this.brandInk,
    required this.brandSoft,
    required this.saida,
    required this.saidaSoft,
  });

  Color get entrada => brandInk;
  Color get entradaSoft => brandSoft;

  static const claro = FcCores(
    surface100: Color(0xFFF3F4F8),
    surface200: Color(0xFFFFFFFF),
    surface300: Color(0xFFE9EBF2),
    line: Color(0xFFE1E4EC),
    lineStrong: Color(0xFF7A8094),
    ink: Color(0xFF0E1222),
    inkMuted: Color(0xFF585E72),
    brand: Color(0xFF2F4BFF),
    brandInk: Color(0xFF2A40E6),
    brandSoft: Color(0xFFE7EAFF),
    saida: Color(0xFFBF321B),
    saidaSoft: Color(0xFFFFE8E3),
  );

  static const escuro = FcCores(
    surface100: Color(0xFF0B0D14),
    surface200: Color(0xFF151925),
    surface300: Color(0xFF1E2333),
    line: Color(0xFF262C3D),
    lineStrong: Color(0xFF6C7388),
    ink: Color(0xFFF2F4FA),
    inkMuted: Color(0xFFA2A8BA),
    brand: Color(0xFF3651F5),
    brandInk: Color(0xFF93A1FF),
    brandSoft: Color(0xFF1C2350),
    saida: Color(0xFFFF7D63),
    saidaSoft: Color(0xFF3A1B15),
  );

  // Cores do tema que está em uso (claro ou escuro)
  static FcCores of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? escuro : claro;
}

ThemeData temaClaro() => _criarTema(FcCores.claro, Brightness.light);
ThemeData temaEscuro() => _criarTema(FcCores.escuro, Brightness.dark);

ThemeData _criarTema(FcCores c, Brightness brilho) {
  final cantos = BorderRadius.circular(10);
  OutlineInputBorder borda(Color cor, [double largura = 1.5]) => OutlineInputBorder(
        borderRadius: cantos,
        borderSide: BorderSide(color: cor, width: largura),
      );

  return ThemeData(
    brightness: brilho,
    scaffoldBackgroundColor: c.surface100,

    colorScheme: ColorScheme(
      brightness: brilho,
      primary: c.brand,
      onPrimary: Colors.white,
      primaryContainer: c.brand,
      onPrimaryContainer: Colors.white,
      secondary: c.brandInk,
      onSecondary: Colors.white,
      secondaryContainer: c.brandSoft,
      onSecondaryContainer: c.brandInk,
      error: c.saida,
      onError: Colors.white,
      surface: c.surface200,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLow: c.surface200,
      surfaceContainer: c.surface200,
      surfaceContainerHigh: c.surface200,
      surfaceContainerHighest: c.surface300,
      outline: c.lineStrong,
      outlineVariant: c.line,
    ),

    textTheme: GoogleFonts.manropeTextTheme(ThemeData(brightness: brilho).textTheme)
        .apply(bodyColor: c.ink, displayColor: c.ink),

    appBarTheme: AppBarThemeData(
      backgroundColor: c.surface100,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),

    cardTheme: CardThemeData(
      color: c.surface200,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.line),
      ),
    ),

    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: c.surface200,
      labelStyle: TextStyle(color: c.inkMuted),
      enabledBorder: borda(c.lineStrong),
      focusedBorder: borda(c.brandInk, 2),
      errorBorder: borda(c.saida),
      focusedErrorBorder: borda(c.saida, 2),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: cantos),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.brand,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}