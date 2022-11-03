import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:Viikkokalenteri/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../assets.dart';

class SymbolsView extends StatefulWidget {
  const SymbolsView({Key? key}) : super(key: key);

  @override
  State<SymbolsView> createState() => _SymbolsViewState();
}

class _SymbolsViewState extends State<SymbolsView> {
  final _vocabulary = Vocabulary._instance;
  List<String> get allSymbols => Assets.instance.symbolFiles;
  String searchTerm = "";

  @override
  Widget build(BuildContext context) {
    final results = Vocabulary.instance.search("sotilas");
    return Scaffold(
      body: Column(
        children: [
          SymbolSearchBar(
            onSearchTermChanged: (String value) {
              setState(() {
                searchTerm = value.trim();
              });
            },
          ),
          const Divider(),
          Expanded(
            child: SymbolsGrid(
              searchTerm: searchTerm,
            ),
          )
        ],
      ),
    );
  }
}

class SymbolsGrid extends StatelessWidget {
  final String searchTerm;
  const SymbolsGrid({required this.searchTerm, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final symbols = searchTerm.isNotEmpty
        ? Vocabulary.instance
            .search(searchTerm)
            .map((e) => Assets.instance.getSymbolPath(e)!)
            .toList()
        : Assets.instance.symbolFiles.toList();
    symbols.insertAll(0, LatestSymbols.instance.latestSymbols);
    return GridView.count(
      crossAxisCount: 4,
      children: symbols
          .map(
            (String path) => IconButton(
              icon: SvgPicture.asset(path),
              onPressed: () {
                LatestSymbols.instance.addSymbol(path);
                Navigator.of(context).pop<String>(path);
              },
            ),
          )
          .toList(),
    );
  }
}

class LatestSymbols {
  static const maxLatestSymbols = 20;
  static final jsonLatestSymbolsName = "latest";
  static LatestSymbols _instance = LatestSymbols._internal();
  static LatestSymbols get instance => _instance;

  Queue<String> latestSymbols = Queue<String>();

  LatestSymbols._internal();

  Map<String, dynamic> toJson() {
    return {jsonLatestSymbolsName: jsonEncode(latestSymbols.toList())};
  }

  factory LatestSymbols.fromJson(Map<String, dynamic> json) {
    _instance.latestSymbols =
        Queue<String>.from(jsonDecode(json[jsonLatestSymbolsName]));
    return _instance;
  }

  void addSymbol(String fileName) {
    if (!latestSymbols.contains(fileName)) {
      latestSymbols.addFirst(fileName);
      if (latestSymbols.length > maxLatestSymbols) {
        latestSymbols.removeLast();
      }
      save();
    }
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("$LatestSymbols");
    if (jsonString != null) {
      _instance = LatestSymbols.fromJson(jsonDecode(jsonString));
    }
  }

  static void save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("$LatestSymbols", jsonEncode(_instance));
  }
}

class SymbolSearchBar extends StatefulWidget {
  final void Function(String value) onSearchTermChanged;
  SymbolSearchBar({Key? key, required this.onSearchTermChanged})
      : super(key: key);

  @override
  State<SymbolSearchBar> createState() => _SymbolSearchBarState();
}

class _SymbolSearchBarState extends State<SymbolSearchBar> {
  static const maxLines = 1;

  late final TextEditingController _editingController;
  final _textFocus = FocusNode();
  final decoration = InputDecoration(
    hintText: "Etsi kuvaa:",
    border: InputBorder.none,
    hintMaxLines: maxLines,
    hintStyle: TextStyle(),
  );

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController();
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            textAlign: TextAlign.center,
            controller: _editingController,
            maxLines: maxLines,
            decoration: decoration,
            focusNode: _textFocus,
            onChanged: widget.onSearchTermChanged,
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: IconButton(
              onPressed: (() => _textFocus.unfocus()),
              icon: Icon(Icons.search),
            ),
          ),
        ),
      ],
    );
  }
}

class Vocabulary {
  ///Maybe one day implement a generic csv class but monster will do for now.
  static const csvPath = "assets/synonyms.csv";
  static const filePathIndex = 0;
  static const synonymsIndex = 1;
  static const closestWordsIndex = 2;
  static const relatedWordsIndex = 3;
  static const categoriesIndex = 4;
  static const csvSeparator = ";";
  static const csvSubSeparator = "&";
  static const eol = "\n";

  static Vocabulary _instance = Vocabulary._internal();
  static Vocabulary get instance => _instance;

  late final _Dictionary _synonyms;
  late final _Dictionary _closestWords;
  late final _Dictionary _relatedWords;
  late final _Dictionary _categories;

  Vocabulary._internal();

  //TODO: Refactor, remove repetition
  static Future<void> load() async {
    final csv = await rootBundle.loadString(csvPath);
    final lines = csv.split(eol).sublist(1); // Ignore first line(header)
    final Map<String, List<String>?> synonymsToAssets = {};
    final Map<String, List<String>?> closestWordsToAssets = {};
    final Map<String, List<String>?> relatedWordsToAsset = {};
    final Map<String, List<String>?> categoriesToAssets = {};
    for (final line in lines) {
      if (line.isEmpty) continue;
      final entries = line.split(csvSeparator);
      final filePath = entries[filePathIndex];
      final synonyms = entries[synonymsIndex].split(csvSubSeparator);
      final closestWords = entries[closestWordsIndex].split(csvSubSeparator);
      final relatedWords = entries[relatedWordsIndex].split(csvSubSeparator);
      final categories = entries[categoriesIndex].split(csvSubSeparator);
      instance._addWords(
          assetPath: filePath,
          words: synonyms,
          wordsToAssets: synonymsToAssets);
      instance._addWords(
          assetPath: filePath,
          words: closestWords,
          wordsToAssets: closestWordsToAssets);
      instance._addWords(
          assetPath: filePath,
          words: relatedWords,
          wordsToAssets: relatedWordsToAsset);
      instance._addWords(
          assetPath: filePath,
          words: categories,
          wordsToAssets: categoriesToAssets);
    }
    instance._synonyms = _Dictionary(
        wordsToAssetPaths: synonymsToAssets, type: _DictionaryType.synonym);
    instance._closestWords = _Dictionary(
        wordsToAssetPaths: closestWordsToAssets,
        type: _DictionaryType.closestWord);
    instance._relatedWords = _Dictionary(
        wordsToAssetPaths: relatedWordsToAsset,
        type: _DictionaryType.relatedWord);
    instance._categories = _Dictionary(
        wordsToAssetPaths: categoriesToAssets, type: _DictionaryType.category);
  }

  void _addWords(
      {required Map<String, List<String>?> wordsToAssets,
      required List<String> words,
      required String assetPath}) {
    for (String word in words) {
      word = word.trim();
      if (wordsToAssets[word] == null) {
        wordsToAssets[word] = [];
      }
      wordsToAssets[word.trim()]?.add(assetPath);
    }
  }

  ///Returns path to symbol asset if there is a match
  Set<String> search(String searchTerm) {
    final ret = Set<String>();
    final searchResults = _synonyms.search(searchTerm)
      ..addAll(_closestWords.search(searchTerm))
      ..addAll(_relatedWords.search(searchTerm))
      ..addAll(_categories.search(searchTerm));
    searchResults.forEach((searchResult) {
      ret.addAll(searchResult.pathsToAssets);
    });
    return ret;
  }
}

class _Dictionary {
  Map<String, List<String>?> wordsToAssetPaths;
  _DictionaryType type;
  _Dictionary({required this.wordsToAssetPaths, required this.type});

  List<_SearchResult> search(String searchTerm) {
    List<_SearchResult> results = [];
    for (final word in wordsToAssetPaths.keys) {
      final pathToAssets = wordsToAssetPaths[word]!;
      if (word.equalsCaseInsensitive(searchTerm)) {
        results.add(_SearchResult(
            pathsToAssets: pathToAssets,
            dictionaryType: type,
            matchType: _SearchMatchType.exact));
      }
      if (word.startsWithCaseInsensitive(searchTerm)) {
        results.add(_SearchResult(
            pathsToAssets: pathToAssets,
            dictionaryType: type,
            matchType: _SearchMatchType.begin));
      }
      if (word.containsCaseInsensitive(searchTerm)) {
        results.add(_SearchResult(
            pathsToAssets: pathToAssets,
            dictionaryType: type,
            matchType: _SearchMatchType.partial));
      }
    }
    return results;
  }
}

extension _CaseInsensitiveComparison on String {
  bool equalsCaseInsensitive(String other) =>
      this.toLowerCase() == other.toLowerCase();
  bool startsWithCaseInsensitive(String other) =>
      this.toLowerCase().startsWith(other.toLowerCase());
  bool containsCaseInsensitive(String other) =>
      this.toLowerCase().contains(other.toLowerCase());
}

class _SearchResult {
  List<String> pathsToAssets;
  _DictionaryType dictionaryType;
  _SearchMatchType matchType;

  _SearchResult(
      {required this.pathsToAssets,
      required this.dictionaryType,
      required this.matchType});
}

enum _DictionaryType { synonym, closestWord, relatedWord, category }

enum _SearchMatchType { exact, begin, partial }
