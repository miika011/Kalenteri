import 'dart:ui';

import 'package:Viikkokalenteri/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
              searchTerm.isNotEmpty
                  ? _vocabulary.search(searchTerm).map((String fileName) =>
                      Assets.instance.getSymbolPath(fileName)!)
                  : allSymbols,
            ),
          )
        ],
      ),
    );
  }
}

class SymbolsGrid extends StatelessWidget {
  final Iterable<String> symbols;

  const SymbolsGrid(this.symbols, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      children: symbols
          .map(
            (String path) => IconButton(
              icon: SvgPicture.asset(path),
              onPressed: () => Navigator.of(context).pop<String>(path),
            ),
          )
          .toList(),
    );
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
    final Map<String, String?> synonymsToAsset = {};
    final Map<String, String?> closestWordsToAssets = {};
    final Map<String, String?> relatedWordsToAsset = {};
    final Map<String, String?> categoriesToAsset = {};
    for (final line in lines) {
      if (line.isEmpty) continue;
      final entries = line.split(csvSeparator);
      final filePath = entries[filePathIndex];
      final synonyms = entries[synonymsIndex].split(csvSubSeparator);
      final closestWords = entries[closestWordsIndex].split(csvSubSeparator);
      final relatedWords = entries[relatedWordsIndex].split(csvSubSeparator);
      final categories = entries[categoriesIndex].split(csvSubSeparator);
      instance._addWords(
          assetPath: filePath, words: synonyms, wordsToAsset: synonymsToAsset);
      instance._addWords(
          assetPath: filePath,
          words: closestWords,
          wordsToAsset: closestWordsToAssets);
      instance._addWords(
          assetPath: filePath,
          words: relatedWords,
          wordsToAsset: relatedWordsToAsset);
      instance._addWords(
          assetPath: filePath,
          words: categories,
          wordsToAsset: categoriesToAsset);
      print(line);
    }
    instance._synonyms = _Dictionary(
        wordsToAssetPaths: synonymsToAsset, type: _DictionaryType.synonym);
    instance._closestWords = _Dictionary(
        wordsToAssetPaths: closestWordsToAssets,
        type: _DictionaryType.closestWord);
    instance._relatedWords = _Dictionary(
        wordsToAssetPaths: relatedWordsToAsset,
        type: _DictionaryType.relatedWord);
    instance._categories = _Dictionary(
        wordsToAssetPaths: categoriesToAsset, type: _DictionaryType.category);
  }

  void _addWords(
      {required Map<String, String?> wordsToAsset,
      required List<String> words,
      required String assetPath}) {
    for (final word in words) {
      wordsToAsset[word.trim()] = assetPath;
    }
  }

  ///Returns path to symbol asset if there is a match
  Set<String> search(String searchTerm) {
    final searchResults = _synonyms.search(searchTerm)
      ..addAll(_closestWords.search(searchTerm))
      ..addAll(_relatedWords.search(searchTerm))
      ..addAll(_categories.search(searchTerm));
    return searchResults.map((result) => result.pathToAsset).toSet();
  }
}

class _Dictionary {
  Map<String, String?> wordsToAssetPaths;
  _DictionaryType type;
  _Dictionary({required this.wordsToAssetPaths, required this.type});

  List<_SearchResult> search(String searchTerm) {
    List<_SearchResult> results = [];
    for (final word in wordsToAssetPaths.keys) {
      final pathToAsset = wordsToAssetPaths[word]!;
      if (word.equalsCaseInsensitive(searchTerm)) {
        results.add(_SearchResult(
            pathToAsset: pathToAsset,
            dictionaryType: type,
            matchType: _SearchMatchType.exact));
      }
      if (word.startsWithCaseInsensitive(searchTerm)) {
        results.add(_SearchResult(
            pathToAsset: pathToAsset,
            dictionaryType: type,
            matchType: _SearchMatchType.begin));
      }
      if (word.containsCaseInsensitive(searchTerm)) {
        results.add(_SearchResult(
            pathToAsset: pathToAsset,
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
  String pathToAsset;
  _DictionaryType dictionaryType;
  _SearchMatchType matchType;

  _SearchResult(
      {required this.pathToAsset,
      required this.dictionaryType,
      required this.matchType});
}

enum _DictionaryType { synonym, closestWord, relatedWord, category }

enum _SearchMatchType { exact, begin, partial }
