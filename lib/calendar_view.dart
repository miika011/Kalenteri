import 'package:flutter/material.dart';
import 'package:kalenteri/util.dart';

class WeekWidget extends StatefulWidget {
  const WeekWidget({Key? key}) : super(key: key);

  @override
  State<WeekWidget> createState() => _WeekWidgetState();
}

class _WeekWidgetState extends State<WeekWidget> {
  DateTime? highlightedDate;
  @override
  Widget build(BuildContext context) {
    goFullscreen();

    const dayWidgetWidthFraction = 1.0 / DateTime.daysPerWeek;
    final dayWidgetWidth =
        RelativeSize(relativeWidth: dayWidgetWidthFraction).forWidthOf(context);
    final now = DateTime.now();
    final fromNowToWeeksMonday = Duration(
        days: -now.weekday +
            1); //DateTime weekdays are 1..7 as per standard hence the +1
    final weeksMonday = now.add(fromNowToWeeksMonday);

    List<Widget> dayWidgets = [];
    for (int i = 0; i < DateTime.daysPerWeek; ++i) {
      final day = weeksMonday.add(Duration(days: i));
      final dayWidget = widgetFor(day);
      dayWidgets.add(SizedBox(
          width: dayWidgetWidth,
          child: GestureDetector(
            child: dayWidget,
            onTap: () => highlight(day),
          )));
    }

    return Row(children: dayWidgets);
  }

  Widget widgetFor(DateTime time) {
    final EdgeInsets margin;
    final BoxDecoration decoration;
    if (_isHighlighted(time)) {
      margin = const EdgeInsets.only(left: 8.5, right: 8.5);
      decoration = _highlightedDecoration;
    } else {
      margin = const EdgeInsets.only(left: 0.5, right: 0.5);
      decoration = _normalDecoration;
    }
    return Container(
      child: DayWidget(
        date: time,
      ),
      margin: margin,
      decoration: decoration,
    );
  }

  bool _isHighlighted(DateTime date) {
    return highlightedDate != null && highlightedDate!.isSameDayAs(date);
  }

  BoxDecoration get _highlightedDecoration {
    return BoxDecoration(boxShadow: [
      BoxShadow(
          spreadRadius: 8.5,
          blurRadius: 8.5,
          //blurStyle: BlurStyle.inner,
          color: Colors.blueGrey.shade300),
    ]);
  }

  BoxDecoration get _normalDecoration {
    const BorderSide borderSide = BorderSide(color: Colors.black);
    return const BoxDecoration(
        border: Border(left: borderSide, right: borderSide));
  }

  void highlight(DateTime day) {
    setState(() => highlightedDate = day);
  }
}

class DayWidget extends StatefulWidget {
  const DayWidget({Key? key, required this.date}) : super(key: key);
  final DateTime date;

  @override
  State<DayWidget> createState() => _DayWidgetState();
}

class _DayWidgetState extends State<DayWidget> {
  List<ActivityWidget> activities = testActivities;
  final textStyle = const TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context) {
    List<Widget> activitiesWithDividers = [];
    for (var element in activities) {
      activitiesWithDividers.addAll([
        element,
        const Divider(
          thickness: 1.0,
          color: Colors.black,
        )
      ]);
    }
    return ColoredBox(
        color: colorForDay(widget.date.weekday),
        child: Column(children: [
          Container(
            child: Column(children: [
              Text(
                "${widget.date.day}.${widget.date.month}.\n${abbreviatedWeekDay(widget.date)}",
                style: textStyle,
                maxLines: 2,
              ),
              const Divider(
                thickness: 5.0,
              )
            ]),
            margin: const EdgeInsets.only(bottom: 20),
          ),
          Column(
            children: activitiesWithDividers,
          ),
        ]));
  }
}

class ActivityWidget extends StatefulWidget {
  const ActivityWidget(this.activity, {Key? key}) : super(key: key);

  final Activity activity;

  @override
  State<ActivityWidget> createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> {
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
      return '';
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
      return const Color(0xffffffff);
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

class NoSuchActivity implements Exception {
  String message;
  NoSuchActivity(this.message);
}

const mauno = Image(image: AssetImage("assets/images/mauno.png"));

final List<ActivityWidget> testActivities = () {
  final a = [
    ActivityWidget(Activity(label: "Eka", timeStamp: DateTime.now())),
    ActivityWidget(Activity(
        label:
            "Toka ja ihan helvetin pitkä mussutus jostain ihan oudosta asiasta",
        timeStamp: DateTime.now())),
    ActivityWidget(Activity(
        label: "Kolmas (Mauno)",
        timeStamp: DateTime.now(),
        imagePath: "assets/images/mauno.png")),
    ActivityWidget(
      Activity(label: "Neljäs", timeStamp: DateTime.now()),
    )
  ];

  List<ActivityWidget> ret = [];
  for (int i = 0; i < 4; ++i) {
    ret.addAll(a);
  }
  return ret;
}();
