// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Assets {
  const Assets();
  static const SVG = SVGAssets();
}

class SVGAssets {
  const SVGAssets();

  SvgPicture done_solid(MaterialColor color) {
    return _loadAsset("assets/icons/svg/done_solid.svg", color);
  }

  SvgPicture done_outlined(MaterialColor color) {
    return _loadAsset("assets/icons/svg/done_outlined.svg", color);
  }

  SvgPicture _loadAsset(String assetPath, MaterialColor color) {
    return SvgPicture.asset(
      assetPath,
      color: color,
    );
  }
}
