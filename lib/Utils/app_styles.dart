import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Theme/colors.dart';
import 'dimensions.dart';

class AppTextStyles {
  static const String fontFamily = 'IBMPlexSansArabic';

  /// Base creator
  static TextStyle _base(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) => TextStyle(
    fontSize: size,
    fontFamily: fontFamily,
    fontWeight: weight,
    color: color,
    overflow: TextOverflow.ellipsis,
  );

  /// Regular
  static TextStyle regular(double size, {Color? color}) =>
      _base(size.sp, weight: FontWeight.w400, color: color);

  /// Medium
  static TextStyle medium(double size, {Color? color}) =>
      _base(size.sp, weight: FontWeight.w500, color: color);

  /// Semi bold
  static TextStyle semiBold(double size, {Color? color}) =>
      _base(size.sp, weight: FontWeight.w600, color: color);

  /// Bold
  static TextStyle bold(double size, {Color? color}) =>
      _base(size.sp, weight: FontWeight.w700, color: color);

  /// Bold
  static TextStyle doubleExtrabold(double size, {Color? color}) =>
      _base(size.sp, weight: FontWeight.w800, color: color);

  /// Extra Bold
  static TextStyle extraBold(double size, {Color? color}) =>
      _base(size.sp, weight: FontWeight.bold, color: color);
}

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final TextAlign? textAlign;
  final int maxLines;

  const CustomText({
    super.key,
    required this.text,
    required this.textStyle,
    this.textAlign,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      style: textStyle,
    );
  }
}

extension TextStyleColorExt on TextStyle {
  TextStyle get navy => copyWith(color: secDarkBlueNavyColor);

  TextStyle get black => copyWith(color: kBlack);

  TextStyle get white => copyWith(color: kWhite);

  TextStyle get red => copyWith(color: kRedFF624D);

  TextStyle get lightGrey => copyWith(color: kC8C8C8);

  TextStyle get grey => copyWith(color: kGrey);

  TextStyle get green => copyWith(color: kGreen4BD37B);

  TextStyle get lightPrimaryColor => copyWith(color: lightPrimaryBlueColor);

  TextStyle primary(BuildContext context) =>
      copyWith(color: Theme.of(context).colorScheme.primary);

  TextStyle secondary(BuildContext context) =>
      copyWith(color: Theme.of(context).colorScheme.secondary);

  TextStyle iconThemeColor(BuildContext context) =>
      copyWith(color: Theme.of(context).iconTheme.color);

  TextStyle surfaceBrightColor(BuildContext context) =>
      copyWith(color: Theme.of(context).colorScheme.surfaceBright);
}

class AppStyles {
  /// field border styles
  static OutlineInputBorder outlineBorder(
    BuildContext context, {
    bool isBorderColorApply = true,
    Color? customBorderColor,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Dimensions.radiusSize15),
    borderSide: BorderSide(
      width: 0.5,
      color: isBorderColorApply
          ? Theme.of(context).colorScheme.primary
          : customBorderColor ?? Colors.transparent,
    ),
  );

  static BoxDecoration outlineBorderDecoration(
    BuildContext context, {
    bool isBorderColorApply = true,
    Color? customBorderColor,
  }) => BoxDecoration(
    borderRadius: BorderRadius.circular(Dimensions.radiusSize15),
    border: Border.all(
      width: 0.5,
      color: isBorderColorApply
          ? Theme.of(context).colorScheme.primary
          : customBorderColor ?? Colors.transparent,
    ),
  );

  static UnderlineInputBorder underlineBorder(BuildContext context) {
    return UnderlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.radiusSize15),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
    );
  }

  /// Divider Line
  static Widget dividerLine({
    double? height,
    double? width,
    Color? color,
    double? marginHorizontal,
    double? marginVertical,
  }) => Container(
    // margin: width != null
    //     ? EdgeInsets.symmetric(
    //         horizontal: marginHorizontal ?? 0,
    //         vertical: marginVertical ?? 0,
    //       )
    //     : null,
    margin: EdgeInsets.symmetric(
      horizontal: SizesDimensions.width(marginHorizontal ?? 0),
      vertical: SizesDimensions.height(marginVertical ?? 0),
    ),
    height: height ?? 0.7,
    width: width,
    color: color ?? secBorderColor,
  );

  static Widget dividerLineVertical({
    double? height,
    double? width,
    Color? color,
    double? marginHorizontal,
    double? marginVertical,
  }) => Container(
    // margin: width != null
    //     ? EdgeInsets.symmetric(horizontal: margin ?? 0)
    //     : null,
    margin: EdgeInsets.symmetric(
      horizontal: SizesDimensions.width(marginHorizontal ?? 0),
      vertical: SizesDimensions.height(marginVertical ?? 0),
    ),
    height: height ?? 29,
    width: width ?? 0.7,
    color: color ?? secBorderColor,
  );
}
