import 'package:flutter/material.dart';

Color primaryBlueColor = const Color(0xff07404D);
Color lightPrimaryBlueColor = const Color(0xff0C677C);
Color primaryGradientColor = const Color(0xff0C677C);
// Color primaryBlueColor = const Color(0xff1934A3);
Color primaryBlueGradientDarkColor = const Color(0xff0C677C);
Color secDarkBlueNavyColor = const Color(0xff415364);
Color secDarkGreyIconColor = const Color(0xff292D32);
Color secBorderColor = const Color(0xffDEE4FF);
Color kWhite = Colors.white;
Color kBlack = Colors.black;
Color kGrey = Colors.grey;
Color kLightGrey = const Color(0xffC8CAC4);
// Color kGreen1ED760 = const Color(0xff1ED760);
Color kGreen1ED760 = const Color(0xff289B2C);
Color kSnackGreen = const Color(0xff4CAF50);
Color kGreen4BD37B = const Color(0xff4BD37B);
Color kDullGreen = const Color(0xff289B2C);
Color k00FFD0 = const Color(0xff00FFD0);
Color k01B291 = const Color(0xff01B291);
Color k20A090 = const Color(0xff20A090);
Color kRedFF624D = const Color(0xffFF624D);
Color kSnackRed = const Color(0xffF44336);
Color kRedLightF9D9DE = const Color(0xffF9D9DE);
Color kRedDarkE35163 = const Color(0xffE35163);
Color kOrangeF79E1B = const Color(0xffF79E1B);
Color anbLogoColor = const Color(0xff0071CE);
Color backgroundColor = const Color(0xffF5F6FA);
const Color kAccentBlue = Color(0xFF2D62ED);
const Color kNeonCyan = Color(0xFF00D2FF);
const Color kDeepGraphite = Color(0xFF0F172A);
const Color kGlassWhite = Color(0xFFFFFFFF);
Color kFFFFFF = const Color(0xffFFFFFF);
Color kDBE9F3 = const Color(0xffDBE9F3);
Color kBCC8FF = const Color(0xffBCC8FF);
Color kC8C8C8 = const Color(0xffC8C8C8);
Color kF3F3F3 = const Color(0xffF3F3F3);
Color kEAEAEA = const Color(0xffEAEAEA);
Color kF2F3F5 = const Color(0xffF2F3F5);
Color k3251D6 = const Color(0xff3251D6);
Color k020088 = const Color(0xff020088);
Color k646464 = const Color(0xff646464);

// --- Constants ---
const Color kPrimaryBlue = Color(0xFF2D62ED);
const Color kSuccessGreen = Color(0xFF27AE60);
const Color kWarningOrange = Color(0xFFF2994A);
const Color kSurfaceGrey = Color(0xFFF8FAFC);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextLight = Color(0xFF64748B);

/// Returns MaterialColor from Color
// MaterialColor createMaterialColor(Color color) {
//   List strengths = <double>[.05];
//   Map<int, Color> swatch = <int, Color>{};
//   final int r = color.red, g = color.green, b = color.blue;
//
//   for (int i = 1; i < 10; i++) {
//     strengths.add(0.1 * i);
//   }
//   for (var strength in strengths) {
//     final double ds = 0.5 - strength;
//     swatch[(strength * 1000).round()] = Color.fromRGBO(
//       r + ((ds < 0 ? r : (255 - r)) * ds).round(),
//       g + ((ds < 0 ? g : (255 - g)) * ds).round(),
//       b + ((ds < 0 ? b : (255 - b)) * ds).round(),
//       1,
//     );
//   }
//   return MaterialColor(color.value, swatch);
// }

Color getFillColor(Set<WidgetState> states, BuildContext context) {
  // Check if the checkbox is checked
  if (states.contains(WidgetState.selected)) {
    // If checked, return the active color
    return Theme.of(context).colorScheme.primary;
  } else {
    // If not checked, return grey
    // return Colors.grey;
    return Theme.of(context).colorScheme.surfaceBright;
  }
}

// class ColorAlphaOpacity {
//   static const double alpha0 = 0; // 0.0 * 255
//   static const double alpha10 = 26; // 0.1 * 255
//   static const double alpha20 = 51; // 0.2 * 255
//   static const double alpha30 = 77; // 0.3 * 255
//   static const double alpha40 = 102; // 0.4 * 255
//   static const double alpha50 = 128; // 0.5 * 255
//   static const double alpha60 = 153; // 0.6 * 255
//   static const double alpha70 = 179; // 0.7 * 255
//   static const double alpha80 = 204; // 0.8 * 255
//   static const double alpha90 = 230; // 0.9 * 255
//   static const double alpha100 = 255; // 1.0 * 255
// }

class ColorAlpha {
  static const int alpha0 = 0; // 0.0 * 255
  static const int alpha10 = 26; // 0.1 * 255
  static const int alpha20 = 51; // 0.2 * 255
  static const int alpha30 = 77; // 0.3 * 255
  static const int alpha40 = 102; // 0.4 * 255
  static const int alpha50 = 128; // 0.5 * 255
  static const int alpha60 = 153; // 0.6 * 255
  static const int alpha70 = 179; // 0.7 * 255
  static const int alpha80 = 204; // 0.8 * 255
  static const int alpha90 = 230; // 0.9 * 255
  static const int alpha100 = 255; // 1.0 * 255
}
