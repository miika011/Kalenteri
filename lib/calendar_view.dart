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

  final Date dayInTheWeek;

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
    return Scaffold(
      body: SafeArea(
        child: PageChanger(
            onForward: () {
              showSnack(context, "Scrolling forward");
            },
            onBackward: () {
              showSnack(context, "Scrolling backward");
            },
            child: buildWeekView(context)),
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

  Column buildWeekView(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: headerHeight(context),
          child: buildHeaderRowForWeek(
            widget.dayInTheWeek,
          ),
        ),
        Expanded(
          child:
              buildActivityGridForWeek(widget.dayInTheWeek, context: context),
        ),
      ],
    );
  }

  double headerHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.08;
  }

  Widget buildHeaderRowForWeek(Date dayInTheWeek) {
    final row = Row(
      children: MondayToSunday(dayInTheWeek)
          .map(
            (date) => Expanded(
              child: Container(
                decoration: decorationForHeader(date),
                child: DayHeaderWidget(
                  date,
                  textStyle: GoogleFonts.getFont(
                    "Cabin Sketch",
                    fontSize: pixelsToFontSizeEstimate(headerHeight(context)),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
    return row;
  }

  Widget buildActivityGridForWeek(Date dayInTheWeek,
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
                  ? addButtonEnabledHeight(context)
                  : addButtonDisabledHeight(context))
              : (_isAddingActivities
                  ? activityHeightWhenAdding(context)
                  : activityHeight(context)),
          duration: WeekWidget.addActivityTransitionDuration,
          curve: Curves.easeInBack,
          child: Row(
            children: gridRows[index],
          ),
        );
      }),
    );
  }

  double addButtonEnabledHeight(BuildContext context) {
    return addButtonDisabledHeight(context) * 4;
  }

  double addButtonDisabledHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.015;
  }

  double activityHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.33;
  }

  double activityHeightWhenAdding(BuildContext context) {
    return activityHeight(context) +
        (addButtonDisabledHeight(context) - addButtonEnabledHeight(context));
  }

  List<List<Widget>> generateGridRows(Date dayInTheWeek,
      {required BuildContext context}) {
    int maxActivities = 0;
    for (Date date in MondayToSunday(dayInTheWeek)) {
      maxActivities =
          max(maxActivities, LogBook().activitiesForDate(date).length);
    }
    List<List<Widget>> gridRows = [];
    for (int rowIndex = 0; rowIndex <= maxActivities * 2; ++rowIndex) {
      final activityIndex = rowIndex ~/ 2;
      List<Widget> row = [];
      for (Date date in MondayToSunday(dayInTheWeek)) {
        final child = rowIndex.isEven
            ? generateAddActivityButton(date: date, index: activityIndex)
            : generateActivityWidget(date: date, index: activityIndex);
        row.add(Expanded(child: child));
      }
      gridRows.add(row);
    }
    return gridRows;
  }

  Widget generateActivityWidget({required Date date, required int index}) {
    final activitiesForDay = LogBook().activitiesForDate(date);
    Widget? child;
    Activity? activity =
        index < activitiesForDay.length ? activitiesForDay[index] : null;

    child = ActivityWidget(
      activity,
      headerText: (index + 1).toString(),
    );

    return Container(
      //padding: EdgeInsets.zero,
      decoration: decorationForActivity(date),
      child: SizedBox(height: activityHeight(context), child: child),
    );
  }

  Widget generateAddActivityButton({required Date date, required int index}) {
    if (_isAddingActivities) {
      return ElevatedButton(
        style: style,
        onPressed: () async {
          final Activity? activity = await Navigator.push<Activity?>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddActivityPage(date: date, activityIndex: index),
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
          child: AddActivityButton(
            iconSize: addButtonIconSize(context),
          ),
        ),
      );
    } else {
      return Container(
        decoration: decorationForAddActivityButton,
      );
    }
  }

  double addButtonIconSize(BuildContext context) {
    return addButtonDisabledHeight(context) * 1.75;
  }

  Decoration decorationForHeader(Date date) {
    final bgColor = backgroundColorForHeader(date);
    return decorationForTile(bgColor);
  }

  Decoration decorationForActivity(Date date) {
    final bgColor = backgroundColorForActivity(date);
    return decorationForTile(bgColor);
  }

  BoxDecoration decorationForTile(Color bgColor) {
    return BoxDecoration(
      color: bgColor,
      border: Border.all(color: bgColor.factorBy(WeekWidget.borderShadeFactor)),
    );
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
}

class PageChanger extends StatefulWidget {
  const PageChanger(
      {Key? key,
      required this.onForward,
      required this.onBackward,
      required this.child})
      : super(key: key);

  @override
  State<PageChanger> createState() => _PageChangerState();

  final VoidCallback onForward;
  final VoidCallback onBackward;
  final Widget child;
}

class _PageChangerState extends State<PageChanger> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        _dragStart = details.globalPosition;
      },
      onHorizontalDragUpdate: (details) {
        final Offset offsetFromStart = Offset(
            details.globalPosition.dx - _dragStart!.dx,
            details.globalPosition.dy - _dragStart!.dy);

        final scrollTreshold = MediaQuery.of(context).size.width * 0.1;
        if (offsetFromStart.dx.abs() > scrollTreshold &&
            offsetFromStart.dx.abs() > offsetFromStart.dy.abs() * 1.33) {
          if (offsetFromStart.dx < 0) {
            widget.onForward();
          } else {
            widget.onBackward();
          }
        }
      },
      child: widget.child,
    );
  }

  Offset? _dragStart;
}

class DayHeaderWidget extends StatelessWidget {
  const DayHeaderWidget(this._date, {Key? key, this.textStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "$dateString $weekDayString",
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  String get dateString {
    return "${_date.day}.${_date.month}.";
  }

  String get weekDayString {
    return _date.abbreviatedWeekDay;
  }

  final TextStyle? textStyle;
  final Date _date;
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
