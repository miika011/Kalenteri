import 'package:flutter/material.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:kalenteri/util.dart';
/*
mport 'dart:ffi';
import 'util.dart';
import 'package:sticky_infinite_list/sticky_infinite_list.dart';
import 'package:loop_page_view/loop_page_view.dart';
*/

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: WeekView(),
    ),
  ));
}

const mauno = Image(image: AssetImage("assets/images/mauno.png"));

class WeekView extends StatefulWidget {
  const WeekView({Key? key}) : super(key: key);

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  @override
  Widget build(BuildContext context) {
    final availableSize = MediaQuery.of(context).size;
    final dayWidgetWidth = availableSize.width / _daysInAWeek;

    goFullscreen();

    return InfiniteListView.builder(
      itemBuilder: (BuildContext context, int index) {
        final now = DateTime.now();
        final fromNowToWeeksMonday = Duration(
            days: -now.weekday + 1); //DateTime weekdays are 1..7 hence +1
        final weeksMonday = now.add(fromNowToWeeksMonday);

        return SizedBox(
            width: dayWidgetWidth,
            child: DayView(date: weeksMonday.add(Duration(days: index))));
      },
      scrollDirection: Axis.horizontal,
      controller: InfiniteScrollController(initialScrollOffset: 0),
    );
  }

  List<Widget> get dayWidgets {
    return List<DayView>.generate(_daysInAWeek, (index) {
      final now = DateTime.now();
      final Duration fromNowToWeeksMonday = Duration(
          days: -now.weekday + 1); //DateTime weekdays are 1..7 hence +1
      final weeksMonday = now.add(fromNowToWeeksMonday);
      return DayView(
        date: weeksMonday.add(Duration(days: index)),
      );
    });
  }
}

class DayView extends StatefulWidget {
  DayView({Key? key, required this.date}) : super(key: key);
  final DateTime date;

  final List<ActivityEntry> activities = [
    ActivityEntry(Activity(label: "Eka", timeStamp: DateTime.now())),
    ActivityEntry(Activity(label: "Toka", timeStamp: DateTime.now())),
    ActivityEntry(Activity(
        label: "Kolmas (Mauno)",
        timeStamp: DateTime.now(),
        imagePath: "assets/images/mauno.png")),
    ActivityEntry(
      Activity(label: "Neljäs", timeStamp: DateTime.now()),
    )
  ];

  WeekDay get weekDay {
    return dateTimeNumberToWeekday(date.weekday);
  }

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  static const dateHeaderHeight = 75.0;
  final ts = const TextStyle(fontSize: 24);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
        color: colorForDay(widget.weekDay),
        child: Column(children: [
          SizedBox(
              height: dateHeaderHeight,
              child: Text(
                abbreviatedWeekDay(widget.date),
                style: ts,
              )),
          Column(
            children: widget.activities,
          ),
        ]));
  }
}

class ActivityEntry extends StatefulWidget {
  const ActivityEntry(this.activity, {Key? key}) : super(key: key);

  final Activity activity;

  @override
  State<ActivityEntry> createState() => _ActivityEntryState();
}

class _ActivityEntryState extends State<ActivityEntry> {
  late Widget image = widget.activity.imagePath != null
      ? Image(image: AssetImage(widget.activity.imagePath!))
      : Container();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [Text(widget.activity.label), image],
    );
  }
}

enum WeekDay { mon, tue, wed, thu, fri, sat, sun }
const _daysInAWeek = 7;

int weekDaytoDateTimeNumber(WeekDay weekDay) {
  return WeekDay.values.indexOf(weekDay) +
      1; //DateTime mon-su are ints 1..7 hence +1
}

WeekDay dateTimeNumberToWeekday(int num) {
  if (num < 1 || num > _daysInAWeek) {
    throw InvalidWeekDayNumber("Invalid number. Expected 1..7 (got $num)");
  }
  return WeekDay.values[num - 1]; //DateTime mon-sun are ints 1..7 henche -1
}

String abbreviatedWeekDay(DateTime dateTime) {
  switch (dateTime.weekday) {
    case 1:
      return "Mon";
    case 2:
      return "Tue";
    case 3:
      return "Wed";
    case 4:
      return "Thu";
    case 5:
      return "Fri";
    case 6:
      return "Sat";
    case 7:
      return "Sun";
    default:
      return "INVALID DATE";
  }
}

Color colorForDay(WeekDay day) {
  switch (day) {
    case WeekDay.mon:
      return const Color(0xff1ace65);
    case WeekDay.tue:
      return const Color(0xff3d51e3);
    case WeekDay.wed:
      return const Color(0xffffffff);
    case WeekDay.thu:
      return const Color(0xff8a6035);
    case WeekDay.fri:
      return const Color(0xffece549);
    case WeekDay.sat:
      return const Color(0xffd95fd0);
    case WeekDay.sun:
      return const Color(0xfff03d5d);
  }
}

class Activity {
  Activity({required this.timeStamp, required this.label, this.imagePath});

  DateTime timeStamp;
  String label;
  String? imagePath;
}

class ActivityLogBook {
  ActivityLogBook();

  final _dateActivity = <DateTime, Activity>{};
  final _activityDate = <Activity, DateTime>{};

  void logActivity({required DateTime timeStamp, required Activity activity}) {
    _dateActivity[timeStamp] = activity;
    _activityDate[activity] = timeStamp;
  }

  Activity getActivity(DateTime timeStamp) {
    final Activity? activity = _dateActivity[timeStamp];
    if (activity == null) {
      throw NoSuchActivity(
          "TimeStamp {$timeStamp} has not been associated with an activity");
    }
    return _dateActivity[timeStamp]!;
  }

  DateTime getTimeStamp(Activity activity) {
    final DateTime? date = _activityDate[activity];
    if (date == null) {
      throw NoSuchActivity("Activity {$activity} hasn't been logged");
    }
    return _activityDate[activity]!;
  }

  void removeByActivity(Activity activity) {
    _removeActivity(activity);
  }

  void removeByTimeStamp(DateTime timeStamp) {
    final activity = getActivity(timeStamp);
    _removeActivity(activity);
  }

  void _removeActivity(Activity activity) {
    final timeStamp = getTimeStamp(activity);
    _activityDate.remove(activity);
    _dateActivity.remove(timeStamp);
  }
}

class AppException implements Exception {
  AppException(this.message);
  String message;

  @override
  String toString() {
    return "${runtimeType.toString()}: $message";
  }
}

class NoSuchActivity extends AppException {
  NoSuchActivity(String message) : super(message);
}

class InvalidWeekDayNumber extends AppException {
  InvalidWeekDayNumber(String message) : super(message);
}
