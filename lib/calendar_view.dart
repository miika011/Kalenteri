import 'package:flutter/material.dart';

import 'dart:math';

import 'package:kalenteri/activities.dart';
import 'package:kalenteri/util.dart';
import 'package:kalenteri/list_extensions.dart';

class WeekWidget extends StatefulWidget {
  const WeekWidget({Key? key}) : super(key: key);

  @override
  State<WeekWidget> createState() => _WeekWidgetState();
}

class _WeekWidgetState extends State<WeekWidget> {
  DateTime? highlightedDate;
  static const paddingWidth = 1.0;

  @override
  Widget build(BuildContext context) {
    goFullscreen();

    final now = DateTime.now();
    final fromNowToWeeksMonday = Duration(
        days: -now.weekday +
            1); //DateTime weekdays are 1..7 as per standard hence the +1
    final weeksMonday = now.add(fromNowToWeeksMonday);

    var mostActivitiesOnADate = 0;
    for (int i = 0; i < DateTime.daysPerWeek; ++i) {
      final day = weeksMonday.add(Duration(days: i));
      final activity = LogBook().activitiesForDay(day);
      mostActivitiesOnADate = max(mostActivitiesOnADate, activity.length);
    }

    final grid = List<Widget>.generate(
        DateTime.daysPerWeek * mostActivitiesOnADate, (index) {
      final weekDayNum = index % DateTime.daysPerWeek;
      final date = weeksMonday.add(Duration(days: weekDayNum));
      final activityIndex = index ~/ DateTime.daysPerWeek;
      final activities = LogBook().activitiesForDay(date);
      return activityIndex < activities.length
          ? ActivityWidget(activities[activityIndex])
          : Container(
              color: colorForDay(date.weekday),
            );
    }, growable: false);

    final headers = <Widget>[];
    for (final DateTime date in MondayToSunday(now)) {
      headers.add(Expanded(
        child: Container(
            color: colorForDay(date.weekday),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("${abbreviatedWeekDay(date)}\n${date.day}.${date.month}",
                    textAlign: TextAlign.center),
                const Divider(
                  thickness: 5,
                  color: Color.fromARGB(151, 39, 23, 23),
                )
              ],
            )),
      ));
    }

    return Column(children: [
      SizedBox(
        height: max(Scale(heightScale: 0.075).forContext(context).height, 50.0),
        child: Row(
          children: headers.separatedBy(
            const Padding(
              padding: EdgeInsets.only(right: paddingWidth),
            ),
          ),
        ),
      ),
      Expanded(
          child: GridView.count(
        crossAxisCount: DateTime.daysPerWeek,
        shrinkWrap: true,
        mainAxisSpacing: paddingWidth,
        crossAxisSpacing: paddingWidth,
        children: grid,
      ))
    ]);
  }
}

class ActivityWidget extends StatelessWidget {
  ActivityWidget(this.activity, {Key? key}) : super(key: key);
  final Activity activity;
  late final Widget image = activity.imagePath != null
      ? Image(image: AssetImage(activity.imagePath!))
      : Container();
  @override
  Widget build(BuildContext context) {
    return Container(
        color: colorForDay(activity.timeStamp.weekday),
        child: Column(
          //mainAxisSize: MainAxisSize.min,
          children: [Expanded(child: Text(activity.label)), image],
        ));
  }
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
    default: //should never happen but the compiler doesn't approve of omitting this
      throw AssertionError(
          "DateTime object's weekday property whould always be [1..7]");
  }
}

Color colorForDay(int weekDayNumber) {
  //
  switch (weekDayNumber) {
    case 1:
      return const Color(0xff1ace65);
    case 2:
      return const Color(0xff3d51e3);
    case 3:
      return const Color(0xffe0e0e0);
    case 4:
      return const Color(0xff8a6035);
    case 5:
      return const Color(0xffece549);
    case 6:
      return const Color(0xffd95fd0);
    case 7:
      return const Color(0xfff03d5d);
    default:
      return const Color(0x00000000);
  }
}

//TEST ACTIVITIES ============>
const mauno = Image(image: AssetImage("assets/images/mauno.png"));

final List<Activity> testActivities = () {
  final a = [
    Activity(label: "Eka", timeStamp: DateTime.now()),
    Activity(
        label:
            "Toka ja ihan helvetin pitkä mussutus jostain ihan oudosta asiasta",
        timeStamp: DateTime.now()),
    Activity(
        label: "Kolmas (Mauno)",
        timeStamp: DateTime.now(),
        imagePath: "assets/images/mauno.png"),
    Activity(
      label: "Neljäs",
      timeStamp: DateTime.now(),
    )
  ];
  final now = DateTime.now();
  final weeksMonday = now.add(Duration(days: 1 - now.weekday));

  List<Activity> ret = [];
  for (int i = 0; i < DateTime.daysPerWeek; ++i) {
    final repeatingActivities = a
        .map((act) => Activity(
            timeStamp: weeksMonday.add(Duration(days: i)),
            label: act.label,
            imagePath: act.imagePath))
        .toList();
    ret.addAll(List.generate(repeatingActivities.length * 4,
        (index) => repeatingActivities[index % repeatingActivities.length],
        growable: true));
  }

  return ret;
}();

void initTestActivities() {
  final rng = Random(1);
  for (final a in testActivities) {
    if (rng.nextBool()) {
      LogBook().logActivity(a);
    }
  }
}

//<============ TEST ACTIVITIES