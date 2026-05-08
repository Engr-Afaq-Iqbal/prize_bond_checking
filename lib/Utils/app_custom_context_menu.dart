import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Utils/dimensions.dart';
import '../Utils/font_styles.dart';

Widget appCustomContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return AdaptiveTextSelectionToolbar(
    anchors: editableTextState.contextMenuAnchors,
    children: [
      buildContextMenuButton(context, 'copy', () {
        editableTextState.copySelection(SelectionChangedCause.toolbar);
      }),
      buildContextMenuButton(context, 'cut', () {
        editableTextState.cutSelection(SelectionChangedCause.toolbar);
      }),
      buildContextMenuButton(context, 'paste', () {
        editableTextState.pasteText(SelectionChangedCause.toolbar);
      }),
      buildContextMenuButton(context, 'selectAll', () {
        editableTextState.selectAll(SelectionChangedCause.toolbar);
      }),
    ],
  );
}

Widget buildContextMenuButton(
  BuildContext context,
  String text,
  VoidCallback onPressed,
) {
  return TextSelectionToolbarTextButton(
    onPressed: onPressed,
    padding: EdgeInsets.symmetric(
      horizontal: SizesDimensions.width(Dimensions.paddingSize3),
    ),
    child: customText(
      text: text.tr,
      textStyle: regular14Black.copyWith(
        color: Theme.of(context).colorScheme.surfaceBright,
      ),
    ),
  );
}
