import 'package:flutter/material.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:kalenteri/util.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: WeekView(),
    ),
  ));
}

const mauno = Image(image: AssetImage("assets/images/mauno.png"));
final List<ActivityEntry> testActivities = [
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

class WeekView extends StatefulWidget {
  const WeekView({Key? key}) : super(key: key);

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  DateTime? highlightedDate;
  @override
  Widget build(BuildContext context) {
    final availableSize = MediaQuery.of(context).size;
    final dayWidgetWidth = availableSize.width / DateTime.daysPerWeek;

    goFullscreen();

    return InfiniteListView.builder(
      itemBuilder: (BuildContext context, int index) {
        final now = DateTime.now();
        final fromNowToWeeksMonday = Duration(
            days: -now.weekday + 1); //DateTime weekdays are 1..7 hence the +1
        final weeksMonday = now.add(fromNowToWeeksMonday);
        final dayToRender = weeksMonday.add(Duration(days: index));

        return GestureDetector(
            onTap: () => setState(() {
                  highlightedDate = dayToRender;
                }),
            child: SizedBox(
              width: dayWidgetWidth,
              child: viewFor(dayToRender),
            ));
      },
      scrollDirection: Axis.horizontal,
      controller: InfiniteScrollController(initialScrollOffset: 0),
    );
  }

  Widget viewFor(DateTime time) {
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
      child: DayView(
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
}

class DayView extends StatefulWidget {
  const DayView({Key? key, required this.date}) : super(key: key);
  final DateTime date;

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  List<ActivityEntry> activities = testActivities;
  final textStyle = const TextStyle(fontSize: 24);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
        color: colorForDay(widget.date.weekday),
        child: Column(children: [
          Text(
            abbreviatedWeekDay(widget.date),
            style: textStyle,
          ),
          Column(
            children: activities,
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
