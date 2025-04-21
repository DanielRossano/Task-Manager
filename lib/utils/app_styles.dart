import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  // Cores principais do aplicativo
  static const Color primaryColor = Color(0xFF3D8BFF);
  static const Color primaryLightColor = Color(0xFFE9F1FF);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF888888);
  static const Color accentColor = Color(0xFF3D8BFF);

  // Cores para categorias
  static const Map<String, Color> categoryColors = {
    'Desenvolvimento': Color(0xFF3D8BFF),
    'Pesquisa': Color(0xFFFFA33D),
    'Design': Color(0xFFFF3D77),
    'Backend': Color(0xFF3DFF8B),
    'Geral': Color(0xFF888888),
  };

  // Estilos de texto
  static TextStyle get headingStyle => GoogleFonts.poppins(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: textColor,
      );

  static TextStyle get subHeadingStyle => GoogleFonts.poppins(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      );

  static TextStyle get titleStyle => GoogleFonts.poppins(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      );

  static TextStyle get bodyStyle => GoogleFonts.poppins(
        fontSize: 14.0,
        color: textColor,
      );

  static TextStyle get bodySmallStyle => GoogleFonts.poppins(
        fontSize: 12.0,
        color: secondaryTextColor,
      );

  // Decorações para containers
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get calendarDayDecoration => const BoxDecoration(
        color: primaryLightColor,
        shape: BoxShape.circle,
      );

  static BoxDecoration get selectedCalendarDayDecoration => const BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
      );

  // Lista de categorias disponíveis
  static const List<String> categories = [
    'Desenvolvimento',
    'Pesquisa', 
    'Design',
    'Backend',
    'Geral',
  ];
}