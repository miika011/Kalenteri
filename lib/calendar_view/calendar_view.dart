import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:kalenteri/activities.dart';
import 'package:kalenteri/add_activity/add_activity_view.dart';
import 'package:kalenteri/animations/animated_box_border.dart';
import 'package:kalenteri/animations/animated_overlay_color.dart';
import 'package:kalenteri/calendar_view/activity_details.dart';
import 'package:kalenteri/util.dart';

class WeekWidget extends StatefulWidget {
  WeekWidget(this.dayInTheWeek, {Key? key}) : super(key: key);

  @override
  State<WeekWidget> createState() => _WeekWidgetState();

  final Date dayInTheWeek;

  static const borderShadeFactor = 0.8;
  static const addActivityTransitionDuration = Duration(milliseconds: 250);
  final GlobalKey draggableKey = GlobalKey();
}

class _WeekWidgetState extends State<WeekWidget> {
  bool _isAddingActivities = false;
  bool _isScrolling = false;
  ActivityDragStatus? activityDragStatus;
  late final ScrollController _scrollController;

  bool get isDraggingActivity => activityDragStatus != null;
  bool _doesAddButtonSurroundDraggedActivity(
      {required int addButtonIndex, required Date addButtonDate}) {
    if (activityDragStatus == null ||
        addButtonDate != activityDragStatus!.draggedActivity.date) return false;
    final offset = addButtonIndex - activityDragStatus!.hoveredOnIndex;
    return offset == 0 || offset == 1;
    //  | AddButton        | <- offset = 0
    //  | Dragged Activity |
    //  | Addbutton        | <- offset = 1
    //Don't move activities
  }

  late Layout layout;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      child: Scrollbar(
          controller: _scrollController,
          //key: ValueKey(dayInTheWeek),
          child: ListView.builder(
            controller: _scrollController,
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
          )),
    );
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
    final width = MediaQuery.of(context).size.width / DateTime.daysPerWeek;
    Widget content;
    if (index < activitiesForDay.length) {
      final activity = activitiesForDay[index];
      final ActivityWidget activityWidget = ActivityWidget(activity);

      final headerText = (index + 1).toString();
      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!_isAddingActivities) {
            openActivityDetailsDialog(activity, index);
          }
        },
        child: LongPressDraggable<Activity>(
          onDragCompleted: () {
            // showSnack(context, "Drag complete");
            setState(() {
              LogBook().deleteActivity(date: date, index: index);
              LogBook().addActivity(
                  activity: Activity(
                      date: activityDragStatus!.hoveredOnDate,
                      hashedImage: activity.hashedImage,
                      text: activity.text),
                  index: activityDragStatus!.hoveredOnIndex);

              activityDragStatus = null;
            });
          },
          onDragEnd: (details) {
            // showSnack(context, "Drag end");

            if (!details.wasAccepted) {
              setState(() {
                activityDragStatus = null;
              });
            }
          },
          onDragStarted: () {
            // showSnack(context, "Drag started");
            setState(() {
              activityDragStatus = ActivityDragStatus(
                  draggedActivityIndex: index,
                  draggedActivity: activity,
                  hoveredOnDate: date,
                  hoveredOnIndex: index);
            });
          },
          onDraggableCanceled: (velocity, offset) {
            showSnack(context, "Drag canceled");
          },
          maxSimultaneousDrags: 1,
          childWhenDragging: Container(),
          //delay: const Duration(seconds: 5),
          data: activity,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: SizedBox(
            width: width * 0.6,
            height: layout.activityHeight(context) * 0.6,
            child: DraggingActivity(
              draggingKey: widget.draggableKey,
              activity: activity,
            ),
          ),
          child: ActivityWidget(
            activity,
            headerText: headerText,
          ),
        ),
      );

      ;
    } else {
      final blankActivity = ActivityWidget(Activity(date: date));
      content = isDraggingActivity && index <= activitiesForDay.length
          ? dragTarget(
              index: index,
              date: date,
              child: AnimatedOverlayColor(
                  color1: const Color.fromARGB(19, 33, 149, 243),
                  color2: const Color.fromARGB(113, 33, 149, 243),
                  child: blankActivity),
            )
          : blankActivity;
    }

    return Container(
      //padding: EdgeInsets.zero,
      decoration: layout.activityDecoration(date),
      child: SizedBox(
        height: layout.activityHeight(context),
        width: width,
        child: content,
      ),
    );
  }

  Future<dynamic> openActivityDetailsDialog(Activity activity, int index) {
    return Navigator.of(context)
        .push(
          DialogRoute(
            useSafeArea: true,
            context: context,
            builder: (context) {
              return ActivityDetailsWidget(activity: activity, index: index);
            },
          ),
        )
        .then((value) => setState(
              () {},
            ));
  }

  Widget generateAddActivityButton({required Date date, required int index}) {
    if (_isAddingActivities &&
        index <= LogBook().activitiesForDate(date).length) {
      final addButton = AddActivityButton(
        onPressed: () => onPressedAddActivity(date: date, index: index),
        layout: layout,
      );
      return dragTarget(index: index, date: date, child: addButton);
    } else {
      return Container(
        decoration: layout.addButtonDecoration,
      );
    }
  }

  DragTarget<Activity> dragTarget(
      {required int index, required Date date, required Widget child}) {
    return DragTarget<Activity>(
      onWillAccept: (activity) {
        if (activity == null) return false;
        final willAccept = !_doesAddButtonSurroundDraggedActivity(
            addButtonIndex: index, addButtonDate: date);
        return willAccept;
      },
      onMove: (details) {
        if (activityDragStatus == null) return;
        setState(
          () {
            activityDragStatus!.hoveredOnDate = date;
            activityDragStatus!.hoveredOnIndex = index;
          },
        );
      },
      builder: (context, candidateData, rejectedData) {
        return isDraggingActivity &&
                !(_doesAddButtonSurroundDraggedActivity(
                    addButtonDate: date, addButtonIndex: index))
            ? AnimatedBoxBorder(
                border1: Border.all(
                  color: const Color.fromARGB(19, 33, 149, 243),
                ),
                border2: Border.all(
                    color: const Color.fromARGB(113, 33, 149, 243), width: 2.5),
                child: child,
              )
            : child;
      },
    );
  }

  void onPressedAddActivity({required Date date, required int index}) async {
    final activity = await Navigator.of(context).push(
      MaterialPageRoute<Activity?>(
        builder: (context) => AddActivityPage(date: date),
      ),
    );
    setState(
      () {
        if (activity != null) {
          LogBook().addActivity(activity: activity, index: index);
        }
      },
    );
  }
}

class ActivityDragStatus {
  ActivityDragStatus({
    required this.draggedActivity,
    required this.draggedActivityIndex,
    required this.hoveredOnDate,
    required this.hoveredOnIndex,
  });

  Date hoveredOnDate;
  int hoveredOnIndex;
  Activity draggedActivity;
  int draggedActivityIndex;

  @override
  operator ==(Object other) =>
      other is ActivityDragStatus &&
      hoveredOnDate == other.hoveredOnDate &&
      hoveredOnIndex == other.hoveredOnIndex;

  @override
  int get hashCode => hashCodeFromObjects([hoveredOnDate, hoveredOnIndex]);
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
    if (activity.hashedImage.imageFilePath == null) return Container();
    return Image(
      image: FileImage(File(activity.hashedImage.imageFilePath!)),
    );
  }

  Widget get _textWidget => Text(
        text,
        style: textStyle,
      );

  bool get hasImage => activity.hashedImage.imageFilePath != null;

  TextStyle get textStyle {
    return const TextStyle(fontFamily: "Unna", overflow: TextOverflow.ellipsis);
  }

  final Activity activity;

  final String? _headerText;
}

class DraggingActivity extends StatelessWidget {
  const DraggingActivity(
      {Key? key, required this.draggingKey, required this.activity})
      : super(key: key);

  final GlobalKey draggingKey;
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FractionalTranslation(
        translation: const Offset(-0.55, -0.55),
        child:
            SizedBox(width: 200, height: 200, child: ActivityWidget(activity)),
      ),
    );
  }
}

class AddActivityButton extends StatelessWidget {
  const AddActivityButton(
      {Key? key, required this.onPressed, required this.layout})
      : super(key: key);
  final VoidCallback onPressed;
  final Layout layout;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: layout.addButtonStyle,
      onPressed: onPressed,
      child: Ink(
        decoration: layout.addButtonDecoration,
        child: Container(
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
              size: layout.addButtonIconSize(context),
            ),
          ),
        ),
      ),
    );
  }

  IconData get icon {
    return Icons.add_circle_outline;
  }
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
      fontSize: date.isToday ? normalFontSize * 1.2 : normalFontSize,
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
    final landscapeStyle = super.headerTextStyle(context: context, date: date);
    final portraitFontSize = landscapeStyle.fontSize != null
        ? landscapeStyle.fontSize! * 0.45
        : null;
    return landscapeStyle.copyWith(fontSize: portraitFontSize);
  }

  @override
  double activityHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.1;
  }

  @override
  double addButtonEnabledHeight(BuildContext context) {
    return addButtonDisabledHeight(context) * 5;
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

String heroTagForActivity({required Activity activity, required int index}) {
  return "${activity.date.toString()}_$index";
}
