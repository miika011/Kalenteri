import 'package:flutter/material.dart';

class PageStyle {
  PageStyle({
    this.autofocusText,
    this.initialText,
  });

  double? dateWidgetFontSize(BuildContext context) => null;
  double? textBoxFontSize(BuildContext context) => null;
  String? initialText;
  bool? autofocusText;
}

class PageStyleForPortrait extends PageStyle {}

class PageStyleForLandscape extends PageStyle {}

class PageStyleForTextDialog extends PageStyle {
  PageStyleForTextDialog() : super(autofocusText: true);
}
