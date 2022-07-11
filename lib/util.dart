import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestButton extends StatelessWidget {
  const TestButton(
      {Key? key,
      required this.onPressed,
      this.label = "TEST",
      this.size = TestButtonSize.huge})
      : super(key: key);

  final VoidCallback onPressed;
  final String label;
  final TestButtonSize size;

  get width {
    switch (size) {
      case TestButtonSize.tiny:
        return 60.0;
      case TestButtonSize.small:
        return 75.0;
      case TestButtonSize.normal:
        return 90.0;
      case TestButtonSize.big:
        return 115.0;
      case TestButtonSize.huge:
        return 140.0;
    }
  }

  get height {
    switch (size) {
      case TestButtonSize.tiny:
        return 20.0;
      case TestButtonSize.small:
        return 30.0;
      case TestButtonSize.normal:
        return 40.0;
      case TestButtonSize.big:
        return 60.0;
      case TestButtonSize.huge:
        return 80.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Container(
          color: Colors.amber,
          child: Center(
            child: Container(color: Colors.pink, child: Text(label)),
          ),
        ),
      ),
    );
  }
}

enum TestButtonSize { tiny, small, normal, big, huge }

void goFullscreen() {
  try {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (e) {
    return;
  }
}

MaterialColor colorToMaterial(Color color) {
  return MaterialColor(color.value, {
    50: Color.fromRGBO(color.red, color.green, color.blue, 0.1),
    100: Color.fromRGBO(color.red, color.green, color.blue, 0.2),
    200: Color.fromRGBO(color.red, color.green, color.blue, 0.3),
    300: Color.fromRGBO(color.red, color.green, color.blue, 0.4),
    400: Color.fromRGBO(color.red, color.green, color.blue, 0.5),
    500: Color.fromRGBO(color.red, color.green, color.blue, 0.6),
    600: Color.fromRGBO(color.red, color.green, color.blue, 0.7),
    700: Color.fromRGBO(color.red, color.green, color.blue, 0.8),
    800: Color.fromRGBO(color.red, color.green, color.blue, 0.9),
    900: Color.fromRGBO(color.red, color.green, color.blue, 1.0),
  });
}

extension SameDay on DateTime {
  bool isSameDayAs(DateTime b) =>
      day == b.day && month == b.month && year == b.year;
}

class Scale {
  Scale({this.widthScale = 1.0, this.heightScale = 1.0});

  Size forContext(BuildContext context) {
    return forSize(MediaQuery.of(context).size);
  }

  Size forSize(Size size) {
    return Size(widthScale * size.width, heightScale * size.height);
  }

  double widthScale;
  double heightScale;
}

//Iterable that iterates through the same week's monday to sunday of a given date.
class MondayToSunday extends Iterable {
  MondayToSunday(this.date);

  @override
  Iterator get iterator => MondayToSundayIterator(date);

  DateTime date;
}

class MondayToSundayIterator extends Iterator<DateTime> {
  MondayToSundayIterator(DateTime date)
      : _weeksMonday = date.add(Duration(days: -date.weekday));

  @override
  DateTime get current => _weeksMonday.add(Duration(days: _index));

  @override
  bool moveNext() {
    if (_index >= DateTime.daysPerWeek) return false;
    ++_index;
    return true;
  }

  final DateTime _weeksMonday;
  int _index = 0;
}
