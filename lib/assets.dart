// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Assets {
  static final _instance = Assets._internal();
  static final symbolsPath = "assets/icons/svg/symbols/";
  bool _isInitialized = false;
  late final List<String> symbolFiles;

  static Assets get instance {
    if (!_instance._isInitialized) {
      _instance.init();
      _instance._isInitialized = true;
    }
    return _instance;
  }

  late Map<String, dynamic> assets;

  void init() async {
    final manifest = await rootBundle.loadString("AssetManifest.json");
    assets = json.decode(manifest);
    symbolFiles = assets.keys
        .where((element) => element.contains(Assets.symbolsPath))
        .toList();
    _isInitialized = true;
  }

  String? getSymbolPath(String symbolFileName) {
    final path = symbolsPath + symbolFileName;
    if (symbolFiles.contains(path)) {
      return path;
    }
  }

  Assets._internal() {}
  final icons = IconAssets();
}

class IconAssets {
  const IconAssets();

  SvgPicture done_solid(Color color) {
    return _loadAsset("assets/icons/svg/done_solid.svg", color: color);
  }

  SvgPicture done_outlined(Color color) {
    return _loadAsset("assets/icons/svg/done_outlined.svg", color: color);
  }

  SvgPicture addSymbol() {
    return _loadAsset("assets/icons/svg/symbols/activity_centre.svg");
  }

  SvgPicture _loadAsset(String assetPath, {Color? color}) {
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
