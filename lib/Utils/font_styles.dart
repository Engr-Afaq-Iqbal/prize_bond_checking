import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Theme/colors.dart';
import 'dimensions.dart';

// String fontIBMRegular = 'IBMPlexSansRegular';
// String fontIBMBold = 'IBMPlexSansBold';
String fontPoppinsRegular = 'Poppins-Regular';
String fontPoppinsLight = 'Poppins-Light';
String fontPoppinsMedium = 'Poppins-Medium';
String fontPoppinsSemiBold = 'Poppins-SemiBold';
String fontPoppinsThin = 'Poppins-Thin';
String fontPoppinsBold = 'Poppins-Bold';

String fontFamily = 'Poppins';

Text customText({
  required String text,
  TextStyle? textStyle,
  TextAlign? textAlign,
  int maxLines = 1,
}) {
  return Text(
    text,
    textAlign: textAlign ?? TextAlign.start,
    style: textStyle,
    maxLines: maxLines,
  );
}

TextStyle regular14PrimaryBlue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(14.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

final TextStyle regular12Red = TextStyle(
  fontSize: Dimensions.fontSize(12.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kSnackRed,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular16Black = TextStyle(
  fontSize: Dimensions.fontSize(16.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular16White = TextStyle(
  fontSize: Dimensions.fontSize(16.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular16WithoutNavyBlue = TextStyle(
  fontSize: Dimensions.fontSize(16.0),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: secDarkBlueNavyColor,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular18Black = TextStyle(
  fontSize: Dimensions.fontSize(18.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);
final TextStyle regular22Black = TextStyle(
  fontSize: Dimensions.fontSize(22.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular14Black = TextStyle(
  fontSize: Dimensions.fontSize(14.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular10NavyBlue = TextStyle(
  fontSize: Dimensions.fontSize(10.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: secDarkBlueNavyColor,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular12Black = TextStyle(
  fontSize: Dimensions.fontSize(12.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold10NavyBlue = TextStyle(
  fontSize: Dimensions.fontSize(10.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: secDarkBlueNavyColor,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold12Black = TextStyle(
  fontSize: Dimensions.fontSize(12.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold14Black = TextStyle(
  fontSize: Dimensions.fontSize(14.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold16NavyBlue = TextStyle(
  fontSize: Dimensions.fontSize(16.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: secDarkBlueNavyColor,
  overflow: TextOverflow.ellipsis,
);
final TextStyle bold18NavyBlue = TextStyle(
  fontSize: Dimensions.fontSize(18.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: secDarkBlueNavyColor,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold20NavyBlue = TextStyle(
  fontSize: Dimensions.fontSize(20.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: secDarkBlueNavyColor,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold22NavyBlue = TextStyle(
  fontSize: Dimensions.fontSize(22.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: secDarkBlueNavyColor,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold26NavyBlue = TextStyle(
  fontSize: Dimensions.fontSize(26.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: secDarkBlueNavyColor,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold26Black = TextStyle(
  fontSize: Dimensions.fontSize(26.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold32Black = TextStyle(
  fontSize: Dimensions.fontSize(32.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold16White = TextStyle(
  fontSize: Dimensions.fontSize(16.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold16Black = TextStyle(
  fontSize: Dimensions.fontSize(16.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold18White = TextStyle(
  fontSize: Dimensions.fontSize(18.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold10White = TextStyle(
  fontSize: Dimensions.fontSize(10.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold12White = TextStyle(
  fontSize: Dimensions.fontSize(12.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold9White = TextStyle(
  fontSize: Dimensions.fontSize(9.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold14White = TextStyle(
  fontSize: Dimensions.fontSize(14.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

TextStyle bold13Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(13.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold12Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(12.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold14Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(14.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold18Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(18.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold20Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(20.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold24Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(24.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold26Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(26.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold28Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(28.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold16Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(16.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold16Blue05(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(16.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary.withAlpha(ColorAlpha.alpha50),
    overflow: TextOverflow.ellipsis,
  );
}

TextStyle bold30Blue(BuildContext context) {
  return TextStyle(
    fontSize: Dimensions.fontSize(30.0.sp),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
    overflow: TextOverflow.ellipsis,
  );
}

final TextStyle regular12White = TextStyle(
  fontSize: Dimensions.fontSize(12.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular14White = TextStyle(
  fontSize: Dimensions.fontSize(14.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.normal,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold28White = TextStyle(
  fontSize: Dimensions.fontSize(28.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold32White = TextStyle(
  fontSize: Dimensions.fontSize(32.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold24White = TextStyle(
  fontSize: Dimensions.fontSize(24.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold24Black = TextStyle(
  fontSize: Dimensions.fontSize(24.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kBlack,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold26White = TextStyle(
  fontSize: Dimensions.fontSize(26.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kWhite,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold14Red = TextStyle(
  fontSize: Dimensions.fontSize(14.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kRedFF624D,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold16Red = TextStyle(
  fontSize: Dimensions.fontSize(16.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kRedFF624D,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold18Grey = TextStyle(
  fontSize: Dimensions.fontSize(18.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold20Grey = TextStyle(
  fontSize: Dimensions.fontSize(20.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold14Grey = TextStyle(
  fontSize: Dimensions.fontSize(14.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular13Grey = TextStyle(
  fontSize: Dimensions.fontSize(13.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.w500,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular14Grey = TextStyle(
  fontSize: Dimensions.fontSize(14.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.w500,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);

final TextStyle regular10Grey = TextStyle(
  fontSize: Dimensions.fontSize(10.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.w500,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);
final TextStyle regular12Grey = TextStyle(
  fontSize: Dimensions.fontSize(12.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.w500,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold12Grey = TextStyle(
  fontSize: Dimensions.fontSize(12.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.w500,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);

final TextStyle bold16Grey = TextStyle(
  fontSize: Dimensions.fontSize(16.0.sp),
  fontFamily: fontFamily,
  fontWeight: FontWeight.bold,
  color: kC8C8C8,
  overflow: TextOverflow.ellipsis,
);
