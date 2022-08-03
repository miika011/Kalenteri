import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kalenteri/activities.dart';
import 'package:kalenteri/add_activity_view.dart';
import 'package:kalenteri/util.dart';

class WeekWidget extends StatefulWidget {
  const WeekWidget(this.dayInTheWeek, {Key? key}) : super(key: key);

  @override
  State<WeekWidget> createState() => _WeekWidgetState();

  final DateTime dayInTheWeek;

  static const activityHeight = 150.0;
  static const imageHeight = activityHeight * 0.55;
  static const addButtonDisabledHeight = 8.0;
  static const addButtonEnabledHeight = 35.0;
  static const borderShadeFactor = 0.8;
  static const addActivityTransitionDuration = Duration(milliseconds: 250);
}

class _WeekWidgetState extends State<WeekWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final availableSize = mq.size;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (details) {
              _dragStart = details.globalPosition;
            },
            onHorizontalDragUpdate: (details) {
              final Offset offsetFromStart = Offset(
                  details.globalPosition.dx - _dragStart!.dx,
                  details.globalPosition.dy - _dragStart!.dy);

              final scrollTreshold = MediaQuery.of(context).size.width * 0.175;
              if (offsetFromStart.dx.abs() > scrollTreshold &&
                  offsetFromStart.dx.abs() > offsetFromStart.dy.abs() * 1.33) {
                if (offsetFromStart.dx < 0) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("scrolling forward")));
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WeekWidget(widget.dayInTheWeek
                              .add(const Duration(days: 7)))));
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("scrolling backwards")));
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WeekWidget(widget.dayInTheWeek
                              .add(const Duration(days: -7)))));
                }
              }
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: availableSize.width,
                      height: headerHeight(context),
                      child: buildHeaderRowForWeek(
                        widget.dayInTheWeek,
                      ),
                    ),
                    Expanded(
                      child: buildActivityGridForWeek(widget.dayInTheWeek,
                          context: context),
                    ),
                  ],
                ),
                // Container(
                //   color: Color.fromARGB(106, 255, 82, 82),
                // ),
              ],
            )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(
          () {
            _isAddingActivities = !_isAddingActivities;
          },
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  double headerHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.08;
  }

  Widget buildHeaderRowForWeek(DateTime dayInTheWeek) {
    var row = Row(
      children: MondayToSunday(dayInTheWeek)
          .map(
            (date) => Expanded(
              child: Container(
                decoration: decorationForHeader(date),
                child: DayHeaderWidget(date),
              ),
            ),
          )
          .toList(),
    );
    return row;
  }

  Widget buildActivityGridForWeek(DateTime dayInTheWeek,
      {required BuildContext context}) {
    //Widget  grid:
    /*  (mon)  (tue)   (wed)   (thu)   (fri)   (sat)   (sun)
          +      +       +       +       +       +       +    <= ListView index 0
        mon[0] tue[0] wed[0]  thu[0]   fri[0] sat[0]     E        ...
          +      +       +       +       +       +       | 
        mon[1]   E       E       E       E       E       E 
          +      |       |       |       |       |       | 
                          ...
        Where:
            - day[i] is {i+1}th activity for given day
            - sunday has no activities in this example
            - + is add activity button
            - E is empty widget (same size as day[i])
            - | is empty widget (same size as + widget)
        So we get a nice, rectangular grid
    */

    //Map <DateTime.weekday weekDay, List<Widget> activitiesForWeekday>

    List<List<Widget>> gridRows =
        generateGridRows(dayInTheWeek, context: context);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: gridRows.length,
      itemBuilder: ((context, index) {
        return AnimatedContainer(
          width: MediaQuery.of(context).size.width,
          height: index.isEven
              ? (_isAddingActivities
                  ? WeekWidget.addButtonEnabledHeight
                  : WeekWidget.addButtonDisabledHeight)
              : activityHeight(context),
          duration: WeekWidget.addActivityTransitionDuration,
          curve: Curves.easeInBack,
          child: Row(
            children: gridRows[index],
          ),
        );
      }),
    );
  }

  double activityHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.17;
  }

  List<List<Widget>> generateGridRows(DateTime dayInTheWeek,
      {required BuildContext context}) {
    int maxActivities = 0;
    for (DateTime dateTime in MondayToSunday(dayInTheWeek)) {
      maxActivities = max(maxActivities,
          LogBook().activitiesForDate(Date.fromDateTime(dateTime)).length);
    }
    List<List<Widget>> gridRows = [];
    for (int rowIndex = 0; rowIndex <= maxActivities * 2; ++rowIndex) {
      final activityIndex = rowIndex ~/ 2;
      List<Widget> row = [];
      for (DateTime day in MondayToSunday(dayInTheWeek)) {
        if (rowIndex.isEven) {
          row.add(
            Expanded(
              child: generateAddActivityButton(day: day, index: activityIndex),
            ),
          );
        } else {
          row.add(
            Expanded(
              child: generateActivityWidget(day: day, index: activityIndex),
            ),
          );
        }
      }
      gridRows.add(row);
    }
    return gridRows;
  }

  Widget generateActivityWidget({required DateTime day, required int index}) {
    final activitiesForDay =
        LogBook().activitiesForDate(Date.fromDateTime(day));
    Widget? child;
    Activity? activity =
        index < activitiesForDay.length ? activitiesForDay[index] : null;

    child = ActivityWidget(
      activity,
      headerText: (index + 1).toString(),
    );

    return Container(
      //padding: EdgeInsets.zero,
      decoration: decorationForActivity(day),
      child: SizedBox(height: activityHeight(context), child: child),
    );
  }

  Widget generateAddActivityButton(
      {required DateTime day, required int index}) {
    if (_isAddingActivities) {
      return ElevatedButton(
        style: style,
        onPressed: () async {
          final Activity? activity = await Navigator.push<Activity?>(
            context,
            MaterialPageRoute(
              builder: (context) => AddActivityWidget(
                  date: Date.fromDateTime(day), activityIndex: index),
            ),
          );
          if (activity != null) {
            setState(
              () {
                LogBook().logActivity(activity, index);
                LogBook.save();
              },
            );
          }
        },
        child: Ink(
          decoration: decorationForAddActivityButton,
          child: const AddActivityButton(
            iconSize: WeekWidget.addButtonDisabledHeight * 1.75,
          ),
        ),
      );
    } else {
      return Container(
        decoration: decorationForAddActivityButton,
      );
    }
  }

  Color backgroundColorForActivity(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return const Color(0xFFAFEEC9);
      case DateTime.tuesday:
        return const Color(0xFFBBC2F5);
      case DateTime.wednesday:
        return const Color(0xFFF4F4F4);
      case DateTime.thursday:
        return const Color(0xFFD6C7B8);
      case DateTime.friday:
        return const Color(0xFFF8F6BF);
      case DateTime.saturday:
        return const Color(0xFFF2C7EF);
      case DateTime.sunday:
        return const Color(0xFFFABBC6);
      default: // should never happen but compiler gets mad if this is left out.
        throw DateTimeRangeError.weekDay(date.weekday);
    }
  }

  Color backGroundColorForHeader(DateTime day) {
    switch (day.weekday) {
      case DateTime.monday:
        return const Color(0xFF83E4AB);
      case DateTime.tuesday:
        return const Color(0xFF96A0F0);
      case DateTime.wednesday:
        return const Color(0xFFEEEEEE);
      case DateTime.thursday:
        return const Color(0xFFBFA991);
      case DateTime.friday:
        return const Color(0xFFF5F19C);
      case DateTime.saturday:
        return const Color(0xFFEAA8E5);
      case DateTime.sunday:
        return const Color(0xFFF796A7);
      default: // should never happen but compiler gets mad if this is left out.
        throw DateTimeRangeError.weekDay(day.weekday);
    }
  }

  Decoration decorationForHeader(DateTime day) {
    final bgColor = backGroundColorForHeader(day);
    return BoxDecoration(
        color: bgColor,
        border:
            Border.all(color: bgColor.factorBy(WeekWidget.borderShadeFactor)));
  }

  Decoration decorationForActivity(DateTime day) {
    final bgColor = backgroundColorForActivity(day);
    return BoxDecoration(
        color: bgColor,
        border:
            Border.all(color: bgColor.factorBy(WeekWidget.borderShadeFactor)));
  }

  Decoration get decorationForAddActivityButton {
    final darkerRed =
        (backGroundColorForAddButton.red * WeekWidget.borderShadeFactor)
            .round();
    final darkerGreen =
        (backGroundColorForAddButton.green * WeekWidget.borderShadeFactor)
            .round();
    final darkerBlue =
        (backGroundColorForAddButton.blue * WeekWidget.borderShadeFactor)
            .round();
    final darkerShade = Color.fromARGB(255, darkerRed, darkerGreen, darkerBlue);
    final gradient = LinearGradient(
        colors: [darkerShade, backGroundColorForAddButton, darkerShade],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter);
    return BoxDecoration(gradient: gradient);
  }

  get backGroundColorForAddButton {
    return const Color(0xFFDDE2E2);
  }

  ButtonStyle get style {
    return ButtonStyle(
        shape: MaterialStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
        ),
        padding:
            MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero));
  }

  bool _isAddingActivities = false;
  Offset? _dragStart;
}

class DayHeaderWidget extends StatelessWidget {
  const DayHeaderWidget(this._date, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "$dateString\n$weekDayString",
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  TextStyle get textStyle {
    return GoogleFonts.getFont("Cabin Sketch", fontSize: 32.0);
  }

  String get dateString {
    return "${_date.day}.${_date.month}.";
  }

  String get weekDayString {
    return abbreviatedWeekDay(_date);
  }

  final DateTime _date;
}

class ActivityWidget extends StatelessWidget {
  const ActivityWidget(this._activity, {Key? key, String? headerText})
      : headerText = headerText ?? "",
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(
          decoration: const BoxDecoration(boxShadow: [
            BoxShadow(color: Color.fromARGB(55, 0, 0, 0), blurRadius: 3)
          ]),
          margin: const EdgeInsets.only(bottom: 3),
          child: Center(
            child: Text(
              headerText,
              style: const TextStyle(
                  fontSize: 20, color: Color.fromARGB(255, 59, 62, 65)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: image,
        ),
        Text(label),
      ],
    );
  }

  String get label => _activity != null ? _activity!.label : "";

  Widget get image => hasImage
      ? Image(
          image: FileImage(_activity!.imageFile!),
        )
      : Container();

  double get imageHeight => hasImage ? WeekWidget.imageHeight : 0.0;

  bool get hasImage => _activity?.imageFile != null;

  TextStyle get textStyle {
    return const TextStyle(fontFamily: "Unna");
  }

  final Activity? _activity;
  final String headerText;
}

class AddActivityButton extends StatelessWidget {
  const AddActivityButton({Key? key, required this.iconSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: const Color(0xFF7A8888),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.none,
        child: Icon(
          icon,
          color: Colors.blueGrey,
          size: iconSize,
        ),
      ),
    );
  }

  IconData get icon {
    return Icons.add_circle_outline;
  }

  final double iconSize;
}

String abbreviatedWeekDay(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return "Ma";
    case DateTime.tuesday:
      return "Ti";
    case DateTime.wednesday:
      return "Ke";
    case DateTime.thursday:
      return "To";
    case DateTime.friday:
      return "Pe";
    case DateTime.saturday:
      return "La";
    case DateTime.sunday:
      return "Su";
    default: //should never happen but the compiler doesn't approve of omitting this
      throw DateTimeRangeError.weekDay(date.weekday);
  }
}

//TEST ACTIVITIES ============>
const mauno = Image(image: AssetImage("assets/images/mauno.png"));

final List<Activity> testActivities = () {
  final a = [
    Activity(label: "Eka", date: Date.fromDateTime(DateTime.now())),
    Activity(
        label:
            "Toka ja ihan helvetin pitkä mussutus jostain ihan oudosta asiasta",
        date: Date.fromDateTime(DateTime.now())),
    Activity(
      label: "Kolmas (Mauno)",
      date: Date.fromDateTime(DateTime.now()),
      imageFile: File("assets/images/mauno.png"),
    ),
    Activity(
      label: "Neljäs",
      date: Date.fromDateTime(DateTime.now()),
    )
  ];
  final now = DateTime.now();
  final weeksMonday = now.add(Duration(days: 1 - now.weekday));

  List<Activity> ret = [];
  for (int i = 0; i < DateTime.daysPerWeek; ++i) {
    final repeatingActivities = a
        .map((act) => Activity(
            date: Date.fromDateTime(weeksMonday.add(Duration(days: i))),
            label: act.label,
            imageFile: act.imageFile))
        .toList();
    ret.addAll(List.generate(repeatingActivities.length,
        (index) => repeatingActivities[index % repeatingActivities.length],
        growable: true));
  }

  return ret;
}();

void initTestActivities() {
  for (final a in testActivities) {
    final i = LogBook().activitiesForDate(a.date).length;
    LogBook().logActivity(a, i);
  }
}

//<============ TEST ACTIVITIES
