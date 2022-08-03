import 'dart:convert';

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
  MondayToSunday(this.dateTime);

  @override
  Iterator get iterator => MondayToSundayIterator(dateTime);

  DateTime dateTime;
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

class DateTimeRangeError extends RangeError {
  DateTimeRangeError.weekDay(int invalidValue)
      : super.range(invalidValue, 1, 7, "weekday number",
            "Integer representing a week day has to be in range [1,7] (monday to sunday) $Iso8601Explanation.");
  DateTimeRangeError.month(int invalidValue)
      : super.range(
            invalidValue,
            1,
            12,
            "month number"
            "Integer representing a month has to be in range [1,12] (Jan to Dec) $Iso8601Explanation.");

  // ignore: constant_identifier_names
  static const String Iso8601Explanation =
      "(ISO 8601 standard used by DateTime objects in the default library)";
}

extension FactorBy on Color {
  Color factorBy(double factor) {
    return Color.fromARGB(alpha, (red * factor).round(),
        (green * factor).round(), (blue * factor).round());
  }
}

class Date {
  Date({required this.day, required this.month, required this.year});
  Date.fromDateTime(DateTime dateTime)
      : day = dateTime.day,
        month = dateTime.month,
        year = dateTime.year;

  Date.fromJson(Map<String, dynamic> json)
      : year = json["year"],
        month = json["month"],
        day = json["day"];

  Map<String, dynamic> toJson() => {'year': year, "month": month, "day": day};

  @override
  bool operator ==(Object other) {
    return other is Date &&
        other.runtimeType == runtimeType &&
        other.day == day &&
        other.month == month &&
        other.year == year;
  }

  @override
  int get hashCode {
    int result = 17;
    result = 37 * result + day.hashCode;
    result = 37 * result + month.hashCode;
    result = 37 * result + year.hashCode;
    return result;
  }

  int day;
  int month;
  int year;
}
