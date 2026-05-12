import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color navyBlue   = Color(0xFF1B4D8E);
const Color mediumBlue = Color(0xFF2E6DA4);
const Color skyBlue    = Color(0xFF5A9FD4);
const Color paleBlue   = Color(0xFFD6E8F7);
const Color orange     = Color(0xFFE87722);
const Color orangeSoft = Color(0xFFF5A55B);

const Color success     = Color(0xFF27AE60);
const Color successBg   = Color(0xFFEAF3DE);
const Color successText = Color(0xFF3B6D11);

const Color danger      = Color(0xFFE24B4A);
const Color dangerBg    = Color(0xFFFCEBEB);
const Color dangerText  = Color(0xFFA32D2D);

const Color warning     = Color(0xFFE67E22);
const Color warningBg   = Color(0xFFFAEEDA);
const Color warningText = Color(0xFF854F0B);

const Color textPrimary   = Color(0xFF1A1A1A);
const Color textSecondary = Color(0xFF4A4A4A);
const Color textTertiary  = Color(0xFF888888);

const Color surfacePrimary   = Color(0xFFFFFFFF);
const Color surfaceSecondary = Color(0xFFF5F7FA);
const Color borderColor      = Color(0x1F000000);

const Color appBarSurface = Color(0xFFEEF4FB);

class AppText {
  static TextStyle h1({Color color = textPrimary}) =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500, color: color);
  static TextStyle h2({Color color = textPrimary}) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: color);
  static TextStyle h3({Color color = textPrimary}) =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: color);
  static TextStyle body({Color color = textSecondary}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color);
  static TextStyle caption({Color color = textTertiary}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: color);
  static TextStyle micro({Color color = textTertiary}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.5,
      );
}

ThemeData appTheme() {
  final base = GoogleFonts.interTextTheme();
  return ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    textTheme: base,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navyBlue,
      primary: navyBlue,
      secondary: orange,
      surface: surfacePrimary,
      background: surfaceSecondary,
      error: danger,
    ),
    scaffoldBackgroundColor: surfaceSecondary,
    appBarTheme: AppBarTheme(
      backgroundColor: appBarSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surfacePrimary,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navyBlue,
        side: const BorderSide(color: navyBlue, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfacePrimary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: navyBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceSecondary,
      side: const BorderSide(color: borderColor, width: 0.5),
      labelStyle: GoogleFonts.inter(fontSize: 12, color: textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 0.5,
      space: 0,
    ),
  );
}
