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

  Date date;
}

class MondayToSundayIterator extends Iterator<Date> {
  MondayToSundayIterator(Date date)
      : _weeksMonday =
            date.toDateTime().add(Duration(days: -date.toDateTime().weekday));

  @override
  Date get current =>
      Date.fromDateTime(_weeksMonday.add(Duration(days: _index)));

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

Color backgroundColorForActivity(Date date) {
  switch (date.weekdayEnum) {
    case Weekday.mon:
      return const Color(0xFFAFEEC9);
    case Weekday.tue:
      return const Color(0xFFBBC2F5);
    case Weekday.wed:
      return const Color(0xFFF4F4F4);
    case Weekday.thu:
      return const Color(0xFFD6C7B8);
    case Weekday.fri:
      return const Color(0xFFF8F6BF);
    case Weekday.sat:
      return const Color(0xFFF2C7EF);
    case Weekday.sun:
      return const Color(0xFFFABBC6);
  }
}

Color backgroundColorForHeader(Date date) {
  switch (date.weekdayEnum) {
    case Weekday.mon:
      return const Color(0xFF83E4AB);
    case Weekday.tue:
      return const Color(0xFF96A0F0);
    case Weekday.wed:
      return const Color(0xFFEEEEEE);
    case Weekday.thu:
      return const Color(0xFFBFA991);
    case Weekday.fri:
      return const Color(0xFFF5F19C);
    case Weekday.sat:
      return const Color(0xFFEAA8E5);
    case Weekday.sun:
      return const Color(0xFFF796A7);
  }
}

class Date {
  Date({required this.day, required this.month, required this.year}) {
    if (!_isSaneState()) {
      throw ArgumentError("Invalid date (y/m/d): $year/$month/$day");
    }
  }
  Date.fromDateTime(DateTime dateTime)
      : day = dateTime.day,
        month = dateTime.month,
        year = dateTime.year;

  factory Date.fromJson(Map<String, dynamic> json) {
    return Date(year: json["year"], month: json["month"], day: json["day"]);
  }

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

  DateTime toDateTime() {
    return DateTime(year, month, day);
  }

  bool get isToday {
    return this == Date.fromDateTime(DateTime.now());
  }

  Weekday get weekdayEnum {
    final weekDayIndex =
        toDateTime().weekday - 1; // DateTime weekdays are [1,7]
    return Weekday.values[weekDayIndex];
  }

  Month get monthEnum {
    final monthIndex = toDateTime().month - 1; //DateTime months are [1,12]
    return Month.values[monthIndex];
  }

  bool _isSaneState() {
    DateTime dt = toDateTime();
    return (dt.day == day && dt.month == month && dt.year == year);
  }

  String get abbreviatedWeekDay {
    switch (weekdayEnum) {
      case Weekday.mon:
        return "Ma";
      case Weekday.tue:
        return "Ti";
      case Weekday.wed:
        return "Ke";
      case Weekday.thu:
        return "To";
      case Weekday.fri:
        return "Pe";
      case Weekday.sat:
        return "La";
      case Weekday.sun:
        return "Su";
    }
  }

  String toDMY({String delimiter = ".", bool endWithDelimiter = true}) {
    return "$day$delimiter$month$delimiter$year${endWithDelimiter ? delimiter : ""}";
  }

  @override
  String toString() {
    return toDMY();
  }

  final int day;
  final int month;
  final int year;
}

enum Weekday { mon, tue, wed, thu, fri, sat, sun }

enum Month { jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec }

showSnack(BuildContext context, String text) {
  final sm = ScaffoldMessenger.of(context);
  sm.clearSnackBars();
  sm.showSnackBar(SnackBar(content: Text(text)));
}

///Rough and maybe bad estimate for font size to be close to [pixels] in height.
double pixelsToFontSizeEstimate(double pixels) {
  return pixels / 16.0 * 12.0;
}
