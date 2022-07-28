import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kalenteri/activities.dart';
import 'package:kalenteri/add_activity_view.dart';
import 'package:kalenteri/util.dart';

import 'dart:math';

class WeekWidget extends StatefulWidget {
  const WeekWidget(this.dayInTheWeek, {Key? key}) : super(key: key);

  @override
  State<WeekWidget> createState() => _WeekWidgetState();

  final DateTime dayInTheWeek;

  static const headerHeight = 90.0;
  static const activityHeight = 150.0;
  static const imageHeight = activityHeight * 0.55;
  static const addButtonDisabledHeight = 8.0;
  static const addButtonEnabledHeight = 35.0;
  static const borderShadeFactor = 0.8;
  static const addActivityTransitionDuration = Duration(milliseconds: 250);
}

class _WeekWidgetState extends State<WeekWidget> {
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

              if (offsetFromStart.dx.abs() > offsetFromStart.dy.abs()) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("scrolling horizontally")));
              }
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: availableSize.width,
                      height: WeekWidget.headerHeight,
                      child: buildHeaderRowForWeek(
                        DateTime.now(),
                      ),
                    ),
                    Expanded(
                      child: buildActivityGridForWeek(DateTime.now(),
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

  Widget buildHeaderRowForWeek(DateTime dayInTheWeek) {
    return Row(
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
              : WeekWidget.activityHeight,
          duration: WeekWidget.addActivityTransitionDuration,
          curve: Curves.easeInBack,
          child: Row(
            children: gridRows[index],
          ),
        );
      }),
    );
  }

  List<List<Widget>> generateGridRows(DateTime dayInTheWeek,
      {required BuildContext context}) {
    List<List<Widget>> gridRows = [];
    bool hasMore = true;
    for (int rowIndex = 0; hasMore; ++rowIndex) {
      final activityIndex = rowIndex ~/ 2;
      List<Widget> row = [];
      hasMore = false;
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
        hasMore = activityIndex <= LogBook().activitiesForDay(day).length;
      }
      if (hasMore) {
        gridRows.add(row);
      }
    }
    return gridRows;
  }

  Widget generateActivityWidget({required DateTime day, required int index}) {
    final activitiesForDay = LogBook().activitiesForDay(day);
    Widget? child;
    if (index < activitiesForDay.length) {
      child = ActivityWidget(activitiesForDay[index]);
    }
    return Container(
      //padding: EdgeInsets.zero,
      decoration: decorationForActivity(day),
      child: child,
    );
  }

  Widget generateAddActivityButton(
      {required DateTime day, required int index}) {
    if (_isAddingActivities) {
      return ElevatedButton(
        style: style,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddActivityWidget(),
          ));
        },
        child: Ink(
          decoration: decorationForAddActivityButton,
          child: const AddActivityButton(),
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
    return GoogleFonts.cabinSketch(fontSize: 42.0);
  }

  String get dateString {
    return "${_date.day}.${_date.month}.";
  }

  String get weekDayString {
    return abbreviatedWeekDay(_date);
  }

  final DateTime _date;
}

class ActivityGrid extends StatelessWidget {
  const ActivityGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class ActivityWidget extends StatelessWidget {
  const ActivityWidget(this._activity, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget? imageOrNull =
        _activity.imagePath != null ? Image.asset(_activity.imagePath!) : null;

    return SizedBox(
      height: WeekWidget.activityHeight,
      child: Wrap(spacing: 0.0, children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
              height: imageOrNull == null ? 0 : imageHeight,
              child: imageOrNull),
        ),
        Text(_activity.label),
      ]),
    );
  }

  get imageHeight => WeekWidget.imageHeight;

  TextStyle get textStyle {
    return const TextStyle(fontFamily: "Unna");
  }

  final Activity _activity;
}

class AddActivityButton extends StatelessWidget {
  const AddActivityButton({Key? key}) : super(key: key);

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

  double get iconSize => WeekWidget.addButtonDisabledHeight * 1.75;

  static const darkenFactor = 0.9;
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
