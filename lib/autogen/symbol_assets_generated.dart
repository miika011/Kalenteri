import 'package:Viikkokalenteri/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SymbolAssets {
  static final SymbolAssets _instance = SymbolAssets._private();
  static SymbolAssets get instance => _instance;
  SymbolAssets._private();

  List<String> get names => <String>[];

  SvgPicture getSymbolFile(String symbolName) {
    SvgPicture? ret;
    try {
      ret = SvgPicture.asset("assets/icons/svg/symbols/${symbolName}.svg");
    } on Exception {
      debugPrint("Couldn't load symbol: ${symbolName}");
      ret = SvgPicture.asset("assets/icons/svg/not_found.svg");
    }
    return ret;
  }

  SymbolAssetSearchResult search(String searchTerm) {
    searchTerm = searchTerm.toLowerCase();
    final result = SymbolAssetSearchResult();
    for (var name in names) {
      name = name.toLowerCase();
      if (name == searchTerm) {
        result.setExactMatch(SymbolAsset(
          name: name,
          symbolPicture: getSymbolFile(name),
        ));
      }
    }

    return result;
  }
}

class SymbolAssetSearchResult {
  SymbolAsset? exactMatch;
  List<SymbolAsset> synonyms = [];
  List<SymbolAsset> closestWords = [];
  List<SymbolAsset> relatedWords = [];
  List<SymbolAsset> categories = [];

  void setExactMatch(SymbolAsset exactMatch) => this.exactMatch = exactMatch;
  void addSynonym(SymbolAsset synonym) => synonyms.add(synonym);
  void addClosestWord(SymbolAsset closestWord) => closestWords.add(closestWord);
  void addRelatedWord(SymbolAsset relatedWord) => relatedWords.add(relatedWord);
  void addCategory(SymbolAsset category) => categories.add(category);
}
