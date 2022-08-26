import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:kalenteri/activities.dart';
import 'package:kalenteri/add_activity/add_activity_view.dart';
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
    layout = MediaQuery.of(context).orientation == Orientation.landscape
        ? LayoutForLandscape()
        : LayoutForPortrait();
    return Scaffold(
      body: SafeArea(
        child: buildWeekView(context),
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
          height: layout.headerHeight(context),
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

  Widget buildHeaderRowForWeek(Date dayInTheWeek) {
    final row = Row(
      children: MondayToSunday(dayInTheWeek).map((date) {
        TextStyle textStyle =
            layout.headerTextStyle(context: context, date: date);
        return Expanded(
          child: Container(
            decoration: layout.headerDecoration(date),
            child: DayHeaderWidget(
              date,
              textStyle: textStyle,
            ),
          ),
        );
      }).toList(),
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

    return NotificationListener(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            setState(() {
              _isScrolling = true;
            });
          } else if (notification is ScrollEndNotification) {
            setState(() {
              _isScrolling = false;
            });
          }
          return false;
        },
        child: ListView.builder(
          //physics: const BouncingScrollPhysics(),
          itemCount: gridRows.length,
          itemBuilder: ((context, index) {
            return AnimatedContainer(
              width: MediaQuery.of(context).size.width,
              height: index.isEven
                  ? (_isAddingActivities
                      ? layout.addButtonEnabledHeight(context)
                      : layout.addButtonDisabledHeight(context))
                  : (_isAddingActivities
                      ? layout.activityHeightWhenAdding(context)
                      : layout.activityHeight(context)),
              duration: WeekWidget.addActivityTransitionDuration,
              curve: Curves.easeInBack,
              child: Row(
                children: gridRows[index],
              ),
            );
          }),
        ));
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
    Widget child;
    Activity activity = index < activitiesForDay.length
        ? activitiesForDay[index]
        : Activity(date: date);
    final headerText = (index + 1).toString();
    child = Stack(
      children: [
        ActivityWidget(
          activity,
          headerText: headerText,
        ),
        AnimatedOpacity(
            //
            duration: const Duration(milliseconds: 400),
            opacity: _isScrolling ? 1 : 0,
            child: SizedBox(
              height: layout.activityHeight(context) * 0.2,
              child: ActivityHeaderWidget(headerText: headerText),
            )),
      ],
    );

    return Container(
      //padding: EdgeInsets.zero,
      decoration: layout.activityDecoration(date),
      child: SizedBox(height: layout.activityHeight(context), child: child),
    );
  }

  Widget generateAddActivityButton({required Date date, required int index}) {
    if (_isAddingActivities &&
        index <= LogBook().activitiesForDate(date).length) {
      return OutlinedButton(
        style: layout.addButtonStyle,
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
          decoration: layout.addButtonDecoration,
          child: AddActivityButton(
            iconSize: layout.addButtonIconSize(context),
          ),
        ),
      );
    } else {
      return Container(
        decoration: layout.addButtonDecoration,
      );
    }
  }

  bool _isAddingActivities = false;
  bool _isScrolling = false;

  late Layout layout;
}

class ActivityHeaderWidget extends StatelessWidget {
  const ActivityHeaderWidget({
    Key? key,
    required this.headerText,
  }) : super(key: key);

  final String headerText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(boxShadow: [
        BoxShadow(color: Color.fromARGB(160, 255, 255, 255), blurRadius: 3)
      ]),
      margin: const EdgeInsets.only(bottom: 3),
      child: Center(
        child: Text(
          headerText,
          style: const TextStyle(
              fontSize: 20, color: Color.fromARGB(255, 59, 62, 65)),
        ),
      ),
    );
  }
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
  const ActivityWidget(this.activity, {Key? key, String? headerText})
      : _headerText = headerText,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColorForActivity(activity.date),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        //physics: const NeverScrollableScrollPhysics(),
        children: [
          Flexible(
              fit: FlexFit.loose,
              flex: hasImage ? 3 : 0,
              child:
                  Align(alignment: Alignment.topCenter, child: _imageWidget)),
          Flexible(flex: hasText ? 1 : 0, child: _textWidget),
        ],
      ),
    );
  }

  String get text => activity.text.trim();
  bool get hasText => text != "";

  String get headerText => _headerText ?? "";

  Widget get _imageWidget {
    return activity.imageFile != null
        ? Image(
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              } else {
                return const CircularProgressIndicator();
              }
            },
            image: FileImage(activity.imageFile!),
          )
        : Container();
  }

  Widget get _textWidget => Text(
        text,
        style: textStyle,
      );

  bool get hasImage => activity.imageFile != null;

  TextStyle get textStyle {
    return const TextStyle(fontFamily: "Unna", overflow: TextOverflow.ellipsis);
  }

  final Activity activity;

  final String? _headerText;
}

class AddActivityButton extends StatelessWidget {
  const AddActivityButton({Key? key, required this.iconSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
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

abstract class Layout {
  double addButtonIconSize(BuildContext context);
  double addButtonEnabledHeight(BuildContext context);
  double addButtonDisabledHeight(BuildContext context);
  double activityHeight(BuildContext context);
  double headerHeight(BuildContext context);

  Decoration headerDecoration(Date date) {
    final bgColor = backgroundColorForHeader(date);
    return tileDecoration(bgColor);
  }

  TextStyle headerTextStyle(
      {required BuildContext context, required Date date}) {
    final decoration = date.isToday ? TextDecoration.underline : null;
    final normalFontSize =
        pixelsToFontSizeEstimate(headerHeight(context) * 0.9);
    final textStyle = TextStyle(
      fontFamily: "Cabin Sketch",
      decoration: decoration,
      fontSize: date.isToday ? normalFontSize * 1.3 : normalFontSize,
    );
    return textStyle;
  }

  double activityHeightWhenAdding(BuildContext context) {
    return activityHeight(context) +
        (addButtonDisabledHeight(context) - addButtonEnabledHeight(context));
  }

  Decoration activityDecoration(Date date) {
    final bgColor = backgroundColorForActivity(date);
    return tileDecoration(bgColor);
  }

  BoxDecoration tileDecoration(Color bgColor) {
    return BoxDecoration(
      color: bgColor,
      border: Border.all(color: bgColor.factorBy(WeekWidget.borderShadeFactor)),
    );
  }

  Decoration get addButtonDecoration {
    Color darkerShade = adjustedBrightness(addButtonBackgroundColor,
        shadeFactor: WeekWidget.borderShadeFactor);
    final gradient = LinearGradient(
        colors: [darkerShade, addButtonBackgroundColor, darkerShade],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter);
    return BoxDecoration(gradient: gradient);
  }

  Color adjustedBrightness(Color c, {required double shadeFactor}) {
    final adjustedRed = _clampColorValue((c.red * shadeFactor).round());
    final adjustedGreen = _clampColorValue((c.green * shadeFactor).round());
    final adjustedBlue = _clampColorValue((c.blue * shadeFactor).round());
    final adjustedColor =
        Color.fromARGB(255, adjustedRed, adjustedGreen, adjustedBlue);
    return adjustedColor;
  }

  int _clampColorValue(int colorValue) {
    return clamp(colorValue, 0, 255);
  }

  get addButtonBackgroundColor {
    return const Color(0xFFDDE2E2);
  }

  ButtonStyle get addButtonStyle {
    return ButtonStyle(
        shape: MaterialStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
        ),
        padding:
            MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero));
  }
}

class LayoutForLandscape extends Layout {
  @override
  double headerHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.08;
  }

  @override
  double activityHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.33;
  }

  @override
  double addButtonEnabledHeight(BuildContext context) {
    return addButtonDisabledHeight(context) * 4;
  }

  @override
  double addButtonDisabledHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.015;
  }

  @override
  double addButtonIconSize(BuildContext context) {
    return addButtonDisabledHeight(context) * 4.0;
  }
}

class LayoutForPortrait extends Layout {
  @override
  double headerHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.075;
  }

  @override
  TextStyle headerTextStyle(
      {required BuildContext context, required Date date}) {
    var landscapeStyle = super.headerTextStyle(context: context, date: date);
    final portraitFontSize =
        pixelsToFontSizeEstimate(headerHeight(context) * 0.4);
    return landscapeStyle.copyWith(fontSize: portraitFontSize);
  }

  @override
  double activityHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.1;
  }

  @override
  double addButtonEnabledHeight(BuildContext context) {
    return addButtonDisabledHeight(context) * 8;
  }

  @override
  double addButtonDisabledHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.005;
  }

  @override
  double addButtonIconSize(BuildContext context) {
    return addButtonDisabledHeight(context) * 5.0;
  }
}

//TEST ACTIVITIES ============>
const mauno = Image(image: AssetImage("assets/images/mauno.png"));

final List<Activity> testActivities = () {
  final a = [
    Activity(text: "Eka", date: Date.fromDateTime(DateTime.now())),
    Activity(
        text:
            "Toka ja ihan helvetin pitkä mussutus jostain ihan oudosta asiasta",
        date: Date.fromDateTime(DateTime.now())),
    Activity(
      text: "Kolmas (Mauno)",
      date: Date.fromDateTime(DateTime.now()),
      imageFile: File("assets/images/mauno.png"),
    ),
    Activity(
      text: "Neljäs",
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
            text: act.text,
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
