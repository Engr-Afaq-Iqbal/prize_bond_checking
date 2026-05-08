import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Theme/colors.dart';
import '../Utils/dimensions.dart';
import '../Utils/font_styles.dart';
import '../Utils/utils.dart';

class AppCustomButton extends StatefulWidget {
  final Widget? title;
  final String? btnTxt;
  final Icon? leading;
  final Function()? onTap;
  final EdgeInsets? padding;
  final Color? bgColor;
  final EdgeInsets? margin;
  final double? borderRadius;
  final MainAxisSize btnTxtAxisSize;
  final Widget? btnChild;
  final bool isBtnRounded;
  final String? toolTipMsg;
  final bool enableToolTip;
  final bool enableLoading;
  final bool isOutLinedButton;
  final double horizontalPadding;
  final double verticalPadding;

  const AppCustomButton({
    super.key,
    this.title,
    this.btnTxt,
    this.leading,
    this.onTap,
    this.padding,
    this.bgColor,
    this.margin,
    this.borderRadius = Dimensions.radiusSize15,
    this.btnTxtAxisSize = MainAxisSize.max,
    this.btnChild,
    this.isBtnRounded = false,
    this.toolTipMsg,
    this.enableToolTip = false,
    this.enableLoading = false,
    this.isOutLinedButton = false,
    this.horizontalPadding = Dimensions.paddingSize15,
    this.verticalPadding = Dimensions.paddingSize12,
  });

  @override
  State<AppCustomButton> createState() => _AppCustomButtonState();
}

///New code with Linear Gradient color background and also Outline logic included
class _AppCustomButtonState extends State<AppCustomButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.bgColor,
          gradient: widget.bgColor != null || widget.isOutLinedButton
              ? null
              : LinearGradient(
                  colors: [primaryBlueColor, primaryGradientColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(
            widget.borderRadius ??
                (widget.isBtnRounded
                    ? Dimensions.radiusSize50
                    : Dimensions.radiusSize15),
          ),
        ),
        child: Container(
          decoration: widget.isOutLinedButton
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ??
                        (widget.isBtnRounded
                            ? Dimensions.radiusSize50
                            : Dimensions.radiusSize15),
                  ),
                  border: Border.all(width: 1, color: Colors.transparent),
                  color: widget.bgColor,
                  gradient: widget.bgColor != null
                      ? null
                      : LinearGradient(
                          colors: [primaryBlueColor, primaryGradientColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                )
              : BoxDecoration(
                  color: widget.bgColor,
                  gradient: widget.bgColor != null
                      ? null
                      : LinearGradient(
                          colors: [primaryBlueColor, primaryGradientColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ??
                        (widget.isBtnRounded
                            ? Dimensions.radiusSize50
                            : Dimensions.radiusSize15),
                  ),
                ),
          child: ElevatedButton(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return kC8C8C8.withAlpha(20); // Custom overlay color on press
                }
                return null;
              }),
              padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(
                  vertical: widget.verticalPadding,
                  horizontal: widget.horizontalPadding,
                ),
              ),
              backgroundColor: WidgetStateProperty.all(
                widget.bgColor != null || widget.isOutLinedButton
                    ? widget.bgColor
                    : Colors.transparent,
              ),
              shadowColor: WidgetStateProperty.all(Colors.transparent),
              surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
              side: widget.isOutLinedButton
                  ? WidgetStateProperty.all(BorderSide.none)
                  : WidgetStateProperty.all(BorderSide.none),
              foregroundColor: WidgetStateProperty.all(kWhite),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ??
                        (widget.isBtnRounded
                            ? Dimensions.radiusSize50
                            : Dimensions.radiusSize15),
                  ),
                  side: widget.isOutLinedButton
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: Dimensions.size1Point5,
                        )
                      : BorderSide.none,
                ),
              ),
            ),
            onPressed: widget.enableLoading && widget.onTap != null
                ? () async {
                    setState(() => _isLoading = true);
                    await widget.onTap!();
                    setState(() => _isLoading = false);
                  }
                : widget.onTap,
            child: Stack(
              children: [
                if (!_isLoading)
                  widget.btnChild ??
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: widget.btnTxtAxisSize,
                        children: [
                          if (widget.leading != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: Dimensions.paddingSize2Point5,
                              ),
                              child: widget.leading!,
                            ),
                          widget.isOutLinedButton
                              ? ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      primaryBlueColor,
                                      primaryGradientColor,
                                    ],
                                    // Gradient colors for outlined text
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds),
                                  child: widget.title ??
                                      customText(
                                        text: widget.btnTxt ?? 'submit'.tr,
                                        textStyle: regular14White.copyWith(
                                          overflow: TextOverflow.fade,
                                        ),
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                      ),
                                )
                              : widget.title ??
                                  customText(
                                    text: widget.btnTxt ?? 'submit'.tr,
                                    textStyle: regular14White.copyWith(
                                      overflow: TextOverflow.fade,
                                    ),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  ),
                        ],
                      ),
                if (widget.enableLoading && _isLoading)
                  Positioned.fill(
                    child: Center(
                      child: progressIndicator(
                        height: Dimensions.size20,
                        width: Dimensions.size20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
