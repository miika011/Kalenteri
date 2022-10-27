// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'autogen/symbol_assets_generated.dart';

class Assets {
  const Assets();
  static const Icons = IconAssets();
}

class IconAssets {
  const IconAssets();

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

class SymbolAsset extends StatelessWidget {
  final String name;
  late final SvgPicture symbolPicture;

  SymbolAsset({required this.name, required this.symbolPicture});

  @override
  Widget build(BuildContext context) {
    return symbolPicture;
  }
}
