import 'package:flutter/material.dart';

import 'dart:math';

import 'package:kalenteri/activities.dart';
import 'package:kalenteri/util.dart';
import 'package:kalenteri/dates.dart';

import 'package:list_extensions/list_extensions.dart';

class WeekWidget extends StatefulWidget {
  const WeekWidget({Key? key}) : super(key: key);

  @override
  State<WeekWidget> createState() => _WeekWidgetState();
}

class _WeekWidgetState extends State<WeekWidget> {
  static const paddingWidth = 0.0;
  DateTime? highlightedDate;

  @override
  Widget build(BuildContext context) {
    goFullscreen();

    final now = DateTime.now();
    final fromNowToWeeksMonday = Duration(
        days: -now.weekday +
            1); //DateTime weekdays are 1..7 as per standard hence the +1
    final weeksMonday = now.add(fromNowToWeeksMonday);

    var mostActivitiesOnADate = 0;
    final Map<WeekDay, List<Widget>> activityWidgets = {};
    for (int i = 0; i < WeekDay.values.length; ++i) {
      activityWidgets[WeekDay.values[i]] = [];
    }

    for (int i = 0; i < DateTime.daysPerWeek; ++i) {
      final day = weeksMonday.add(Duration(days: i));
      final activitiesForDay = LogBook().activitiesForDay(day);
      final weekDay = WeekDay.values[i];
      final List<Widget> widgetsForDay = (activitiesForDay
          .map((activity) => ActivityWidget(activity) as Widget)).toList();
      mostActivitiesOnADate = max(mostActivitiesOnADate, widgetsForDay.length);
      activityWidgets[weekDay] = widgetsForDay;
    }

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
        height: max(Scale(heightScale: 0.075).forContext(context).height, 60.0),
        child: Row(
          children: headers.separatedBy(
            const Padding(
              padding: EdgeInsets.only(right: paddingWidth),
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView.separated(
          itemCount: mostActivitiesOnADate,
          separatorBuilder: (context, index) {
            return Row(
              children: _dividerRow,
            );
          },
          itemBuilder: (context, vertIndex) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 150,
              child: AspectRatio(
                  aspectRatio: (MediaQuery.of(context).size.width / 7) / 150,
                  child: Row(
                    children: List<Widget>.generate(
                      DateTime.daysPerWeek,
                      (horIndex) {
                        final daysActivities =
                            activityWidgets[WeekDay.values[horIndex]]!;
                        final widget = vertIndex < daysActivities.length
                            ? daysActivities[vertIndex]
                            : Container(
                                color: colorForDay(horIndex + 1),
                              );
                        return SizedBox(
                          width: MediaQuery.of(context).size.width /
                              DateTime.daysPerWeek,
                          child: widget,
                        );
                      },
                    ),
                  )),
            );
          },
        ),
      ),
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
          children: [
            Expanded(child: Text(activity.label)),
            Expanded(child: image)
          ],
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

final _dividerRow = List<Widget>.generate(
    DateTime.daysPerWeek,
    (index) => Container(
          color: colorForDay(index + 1),
          child: const Divider(),
        ));

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
    //if (rng.nextBool()) {
    LogBook().logActivity(a);
    //}
  }
}

//<============ TEST ACTIVITIES
