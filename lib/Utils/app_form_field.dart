import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:prize_bond_app/Utils/utils.dart';

import '../Config/app_config.dart';
import '../Theme/colors.dart';
import '../Utils/dimensions.dart';
import '../Utils/font_styles.dart';
import 'app_custom_context_menu.dart';
import 'app_styles.dart';
import 'images_url.dart';

class AppFormField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? title;
  final bool isLabel;
  final IconData? icon;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isPasswordField;
  final bool enabled;
  final double? height;
  final int maxLines;
  final Function()? onTap;
  final bool readOnly;
  final bool? isDense;
  final bool isOutlineBorder;
  final bool isBorderColorApply;
  final List<TextInputFormatter>? inputFormatterList;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final Function()? onEditingComp;
  final int? maxLength;
  final double? width;
  final Widget? child;
  final TextStyle? textStyle;
  final bool contextMenuBuilder;
  final TextAlign textAlign;
  final bool isBgColorApply;
  final Widget? prefix;
  final bool isCalender;
  final TextStyle? labelTextStyle;
  final Color? customBorderColorInActive;
  final Color? customBorderColorActive;
  final double contentPaddingVertical;
  final double contentPaddingHorizontal;

  const AppFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.title,
    this.isLabel = true,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.isPasswordField = false,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.height,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
    this.isDense,
    this.isOutlineBorder = true,
    this.isBorderColorApply = true,
    this.inputFormatterList,
    this.validator,
    this.onChanged,
    this.margin,
    this.padding = const EdgeInsets.only(bottom: Dimensions.paddingSize15),
    this.prefixIcon,
    this.suffixIcon,
    this.onEditingComp,
    this.maxLength,
    this.width,
    this.child,
    this.suffix,
    this.textStyle,
    this.contextMenuBuilder = false,
    this.textAlign = TextAlign.start,
    this.isBgColorApply = false,
    this.prefix,
    this.isCalender = false,
    this.labelTextStyle,
    this.customBorderColorActive,
    this.customBorderColorInActive,
    this.contentPaddingVertical = Dimensions.paddingSize5,
    this.contentPaddingHorizontal = Dimensions.paddingSize10,
  });

  @override
  AppFormFieldState createState() => AppFormFieldState();
}

class AppFormFieldState extends State<AppFormField> {
  late FocusNode _internalFocusNode;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _internalFocusNode.hasFocus;
    return Container(
      // width: widget.width,
      constraints: BoxConstraints(
        /// TODO: TextField Responsiveness
        minWidth:
            // (ResponsiveWrapper.of(context).isLargerThan('TABLET_S') )
            //     ?
            widget.width ?? Dimensions.size300,
        // : 300
        maxWidth: widget.width ?? double.infinity,
      ),
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding,
      decoration: (widget.isBgColorApply)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSize15),
              color: Theme.of(context).colorScheme.surfaceContainer,
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            customText(text: widget.title!, textStyle: bold14Black),
          // Text(widget.title!,
          //     style: const TextStyle(fontWeight: FontWeight.w500)),
          widget.child ??
              TextFormField(
                textAlign: widget.textAlign,
                contextMenuBuilder: widget.contextMenuBuilder
                    ? (context, editableTextState) =>
                        appCustomContextMenu(context, editableTextState)
                    : null,
                maxLength: widget.maxLength,
                focusNode: widget.focusNode,
                enableInteractiveSelection: true,
                // validator: widget.validator,
                validator: widget.validator != null
                    ? (value) {
                        if (widget.validator!(value) != null) {
                          return widget.validator!(value);
                        }
                        // Custom email validation
                        if (widget.keyboardType == TextInputType.emailAddress &&
                            !isValidEmail(value)) {
                          return 'pleaseEnterAValidEmailAddress'.tr;
                        }
                        return null;
                      }
                    : (value) {
                        // Custom email validation
                        if (widget.keyboardType == TextInputType.emailAddress &&
                            !isValidEmail(value)) {
                          return 'pleaseEnterAValidEmailAddress'.tr;
                        }
                        return null;
                      },
                decoration: InputDecoration(
                  // isDense: widget.isDense ??
                  //     ResponsiveWrapper.of(context).isSmallerThan(DESKTOP),
                  // // filled: true,
                  errorBorder: OutlineInputBorder(
                    // When there is an error and not focused
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusSize15,
                    ),
                    borderSide: BorderSide(color: kSnackRed),
                  ),
                  errorStyle: regular12Red,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: widget.contentPaddingHorizontal,
                    vertical: widget.contentPaddingVertical,
                  ),
                  labelText: (widget.isLabel && widget.title == null)
                      ? widget.labelText
                      : null,
                  hintText: (widget.hintText != null) ? widget.hintText : null,
                  hintStyle: regular14Black.copyWith(
                    color: widget.customBorderColorActive ??
                        Theme.of(context).iconTheme.color?.withAlpha(40),
                  ),
                  labelStyle: widget.labelTextStyle ??
                      regular14Black.copyWith(
                        color: widget.customBorderColorActive ??
                            Theme.of(context).iconTheme.color,
                      ),
                  alignLabelWithHint: true,
                  prefixIcon: (widget.prefixIcon != null)
                      ? widget.prefixIcon
                      : (widget.icon != null)
                          ? Icon(
                              widget.icon,
                              color: widget.customBorderColorActive ??
                                  Colors.grey.withAlpha(ColorAlpha.alpha40),
                            )
                          : null,
                  border: widget.isOutlineBorder
                      ? AppStyles.outlineBorder(
                          context,
                          customBorderColor: widget.customBorderColorActive,
                          isBorderColorApply: widget.isBorderColorApply,
                        )
                      : AppStyles.underlineBorder(context),
                  enabledBorder: widget.isOutlineBorder
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSize15,
                          ),
                          borderSide: BorderSide(
                            color: isFocused
                                ? widget.customBorderColorActive ??
                                    Theme.of(context).colorScheme.primary
                                : widget.customBorderColorInActive ??
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceBright,
                          ),
                        )
                      : AppStyles.underlineBorder(context),
                  focusedBorder: widget.isOutlineBorder
                      ? AppStyles.outlineBorder(
                          context,
                          customBorderColor: widget.customBorderColorActive,
                          isBorderColorApply: widget.isBorderColorApply,
                        )
                      : AppStyles.underlineBorder(context),
                  prefix: (widget.prefix != null) ? widget.prefix : null,
                  suffix: (widget.suffix != null) ? widget.suffix : null,
                  suffixIcon: (widget.suffixIcon != null)
                      ? widget.suffixIcon
                      : (widget.isPasswordField)
                          ? _buildPasswordFieldVisibilityToggle()
                          : widget.isCalender
                              ? _calendarIcon()
                              : null,
                ),
                style: widget.textStyle ??
                    regular14Black.copyWith(
                      color: widget.customBorderColorActive ??
                          Theme.of(context).iconTheme.color,
                    ),

                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatterList ??
                    ((widget.keyboardType == TextInputType.number)
                        ? [
                            FilteringTextInputFormatter.allow(
                              RegExp("[0-9-+.]"),
                            ),
                          ]
                        : (widget.keyboardType == TextInputType.phone)
                            ? [
                                FilteringTextInputFormatter.allow(
                                    RegExp("[0-9+]"))
                              ]
                            : []),

                cursorColor: widget.customBorderColorActive ??
                    Theme.of(context).colorScheme.primary,
                obscureText: widget.isPasswordField ? _obscureText : false,
                controller: widget.controller,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                onTap: widget.onTap,
                readOnly: widget.readOnly,
                onChanged: widget.onChanged,
                onEditingComplete: widget.onEditingComp,
                // onFieldSubmitted: widget.onFieldSub,
                textCapitalization: (widget.keyboardType ==
                            TextInputType.emailAddress ||
                        widget.keyboardType == TextInputType.visiblePassword)
                    ? TextCapitalization.none
                    : (widget.keyboardType == TextInputType.name)
                        ? TextCapitalization.words
                        : TextCapitalization.sentences,
              ),
        ],
      ),
    );
  }

  Widget _buildPasswordFieldVisibilityToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _obscureText = !_obscureText);
      },
      // onLongPressStart: (_) => setState(() => _obscureText = false),
      // onLongPressEnd: (_) => setState(() => _obscureText = true),
      // onTapDown: (_) => setState(
      //     () => _obscureText = false), // Password visible when touching
      // onTapUp: (_) => setState(
      //     () => _obscureText = true), // Password hidden when touch is released
      // onTapCancel: () => setState(() => _obscureText = true),
      child: Icon(
        _obscureText ? Icons.visibility_off : Icons.visibility,
        color: _internalFocusNode.hasFocus
            ? widget.customBorderColorActive ??
                Theme.of(context).colorScheme.primary
            : widget.customBorderColorActive ??
                Theme.of(context).colorScheme.surfaceBright,
      ),
    );
  }

  Widget _calendarIcon() {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSize10),
      child: SvgPicture.asset(
        '${AppConfig.imgUrl}$calenderImg',
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.surfaceBright,
          BlendMode.srcIn,
        ),
        // color: Theme.of(context).colorScheme.surfaceBright,
      ),
    );
  }
}
