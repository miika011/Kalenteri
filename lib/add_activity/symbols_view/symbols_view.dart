import 'dart:ui';

import 'package:Viikkokalenteri/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../assets.dart';

class SymbolsView extends StatelessWidget {
  final onPressed = () {};

  SymbolsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SymbolSearchBar(
            onPressed: onPressed,
          ),
          const Divider(),
          Expanded(
            child: SymbolsGrid(),
          )
        ],
      ),
    );
  }
}

class SymbolsGrid extends StatefulWidget {
  const SymbolsGrid({
    Key? key,
  }) : super(key: key);

  @override
  State<SymbolsGrid> createState() => _SymbolsGridState();
}

class _SymbolsGridState extends State<SymbolsGrid> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      children: Assets.instance.symbolFiles
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
  final VoidCallback onPressed;
  SymbolSearchBar({Key? key, required this.onPressed}) : super(key: key);

  @override
  State<SymbolSearchBar> createState() => _SymbolSearchBarState();
}

class _SymbolSearchBarState extends State<SymbolSearchBar> {
  late final TextEditingController _editingController;
  static const maxLines = 1;
  final decoration = InputDecoration(
    hintText: "Etsi symbolia",
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
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: IconButton(
              onPressed: widget.onPressed,
              icon: Icon(Icons.search),
            ),
          ),
        ),
      ],
    );
  }
}
