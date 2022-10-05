import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:kalenteri/activities.dart';
import 'package:kalenteri/add_activity/add_activity_view.dart';
import 'package:kalenteri/animations/animated_box_border.dart';
import 'package:kalenteri/animations/animated_overlay_color.dart';
import 'package:kalenteri/calendar_view/activity_details.dart';
import 'package:kalenteri/util.dart';

class WeekWidget extends StatefulWidget {
  final Date dayInTheWeek;

  static const borderShadeFactor = 0.8;
  static const addActivityTransitionDuration = Duration(milliseconds: 250);
  static const addActivityTransitionCurve = Curves.easeInBack;
  static const highlightColor1 = Color.fromARGB(178, 33, 255, 33);
  static const highlightColor2 = Color.fromARGB(150, 22, 232, 85);
  static const highlightAnimationDuration = Duration(milliseconds: 1000);

  final GlobalKey draggedKey = GlobalKey();

  WeekWidget(this.dayInTheWeek, {Key? key}) : super(key: key);

  @override
  State<WeekWidget> createState() => _WeekWidgetState();
}

class _WeekWidgetState extends State<WeekWidget> with TickerProviderStateMixin {
  bool _isAddingActivities = false;
  ActivityDragStatus? activityDragStatus;
  late final ScrollController _scrollController;
  bool _fadeFloatingAddButton = false;
  double get _floatingAddButtonOpacity => _fadeFloatingAddButton ? 0.4 : 1.0;

  bool get isDraggingActivity => activityDragStatus != null;
  void stopDragging() => activityDragStatus = null;

  bool _doesAddButtonSurroundDraggedActivity(
      {required int addButtonIndex, required Date addButtonDate}) {
    if (!isDraggingActivity ||
        addButtonDate != activityDragStatus!.draggedActivity.date) return false;
    final offset = addButtonIndex - activityDragStatus!.draggedActivityIndex;
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
        child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) => fadeFloatingAddButton(),
            onPointerUp: (event) => showFloatingAddButton(),
            onPointerCancel: (event) => showFloatingAddButton(),
            child: buildWeekView(context)),
      ),
      floatingActionButton: Opacity(
        opacity: _floatingAddButtonOpacity,
        child: SizedBox(
          height: layout.floatingAddButtonWidthAndHeight(context),
          width: layout.floatingAddButtonWidthAndHeight(context),
          child: FloatingAddButton(
            iconSize: layout.floatingAddButtonIconSize(context),
            vsync: this,
            onPressed: () => setState(
              () {
                _isAddingActivities = !_isAddingActivities;
              },
            ),
          ),
        ),
      ),
    );
  }

  void showFloatingAddButton() =>
      setState(() => _fadeFloatingAddButton = false);

  void fadeFloatingAddButton() => setState(() => _fadeFloatingAddButton = true);

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

    return Scrollbar(
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
            curve: WeekWidget.addActivityTransitionCurve,
            child: Row(
              children: gridRows[index],
            ),
          );
        }),
      ),
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

      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_isAddingActivities) {
            openActivityDetailsDialog(activity, index);
          }
        },
        child: _isAddingActivities
            ? DraggedActivity(
                scrollController: _scrollController,
                draggingKey: widget.draggedKey,
                activity: activity,
                onDragCompleted: () {
                  // showSnack(context, "Drag complete");
                  setState(() {
                    LogBook().deleteActivity(
                        date: activityDragStatus!.draggedActivity.date,
                        index: activityDragStatus!.draggedActivityIndex);

                    final addIndex = activityDragStatus!.draggedActivity.date !=
                                activityDragStatus!.hoveredOnDate ||
                            activityDragStatus!.hoveredOnIndex < index
                        ? activityDragStatus!.hoveredOnIndex
                        : activityDragStatus!.hoveredOnIndex - 1;

                    LogBook().addActivity(
                        activity: Activity(
                            date: activityDragStatus!.hoveredOnDate,
                            hashedImage: activity.hashedImage,
                            text: activity.text),
                        index: addIndex);

                    stopDragging();
                  });
                },
                onDragEnd: (details) {
                  // showSnack(context, "Drag end");

                  if (!details.wasAccepted) {
                    setState(() {
                      stopDragging();
                    });
                  }
                },
                onDragStarted: () {
                  // showSnack(context, "Drag started");
                  setState(() {
                    activityDragStatus = ActivityDragStatus(
                        draggedActivityIndex: index,
                        draggedActivity: activity,
                        hoveredOnDate: activity.date,
                        hoveredOnIndex: index);
                  });
                },
                onDraggableCanceled: (velocity, offset) {
                  // showSnack(context, "Drag canceled");
                  setState(() {
                    stopDragging();
                  });
                },
                sizeWhenDragged: Size(
                    MediaQuery.of(context).size.width /
                        DateTime.daysPerWeek *
                        0.75,
                    layout.activityHeight(context) * 0.75))
            : ActivityWidget(activity),
      );
    } else {
      final blankActivity = ActivityWidget(Activity(date: date));
      content = ((isDraggingActivity && index <= activitiesForDay.length) &&
              activityDragStatus!.draggedActivity.date != date)
          ? dragTarget(
              index: index,
              date: date,
              child: AnimatedOverlayColor(
                duration: WeekWidget.highlightAnimationDuration,
                color1: WeekWidget.highlightColor1,
                color2: WeekWidget.highlightColor2,
                vsync: this,
                child: blankActivity,
              ),
            )
          : blankActivity;
    }

    return Container(
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
      final child = dragTarget(index: index, date: date, child: addButton);
      return isDraggingActivity &&
              !(_doesAddButtonSurroundDraggedActivity(
                  addButtonDate: date, addButtonIndex: index))
          ? AnimatedBoxBorder(
              duration: WeekWidget.highlightAnimationDuration,
              border1: Border.all(
                color: WeekWidget.highlightColor1,
              ),
              border2: Border.all(
                color: WeekWidget.highlightColor2,
                width: 3.5,
              ),
              vsync: this,
              child: child,
            )
          : child;
    } else {
      return Container(
        decoration: layout.addButtonDecoration,
      );
    }
  }

  DragTarget<Activity> dragTarget(
      {required int index, required Date date, required Widget child}) {
    return DragTarget<Activity>(
      onMove: (details) {
        if (!isDraggingActivity) return;
        setState(
          () {
            activityDragStatus!.hoveredOnDate = date;
            activityDragStatus!.hoveredOnIndex = index;
          },
        );
      },
      builder: (context, candidateData, rejectedData) {
        return child;
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

class FloatingAddButton extends StatefulWidget {
  final VoidCallback onPressed;
  final TickerProvider? vsync;
  final double iconSize;

  const FloatingAddButton(
      {Key? key, this.vsync, required this.onPressed, required this.iconSize})
      : super(key: key);

  @override
  State<FloatingAddButton> createState() => _FloatingAddButtonState();
}

class _FloatingAddButtonState extends State<FloatingAddButton>
    with TickerProviderStateMixin {
  late final AnimationController _rotateAnimationController;
  late final Animation<double> _rotateAnimation;
  late final TickerProvider vsync;

  @override
  void initState() {
    super.initState();
    vsync = widget.vsync ?? this;
    _rotateAnimationController = AnimationController(
      vsync: vsync,
      duration: WeekWidget.addActivityTransitionDuration +
          const Duration(milliseconds: 200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _rotateAnimationController.reset();
        }
      });
    _rotateAnimation = _rotateAnimationController.drive(
      Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _rotateAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotateAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          _rotateAnimationController.forward();
          widget.onPressed();
        },
        label: Row(
          children: [
            Icon(
              Icons.edit,
              size: widget.iconSize,
            ),
            Icon(
              Icons.add,
              size: widget.iconSize,
            )
          ],
        ),
      ),
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
  const ActivityWidget(this.activity, {Key? key}) : super(key: key);

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
          Flexible(flex: hasText ? 1 : 0, child: _textWidget(context)),
        ],
      ),
    );
  }

  String get text => activity.text.trim();
  bool get hasText => text != "";

  Widget get _imageWidget {
    if (activity.hashedImage.imageFilePath == null) return Container();
    return Image(
      image: FileImage(File(activity.hashedImage.imageFilePath!)),
    );
  }

  Widget _textWidget(BuildContext context) => Text(
        text,
        style: textStyle(context),
        overflow: TextOverflow.fade,
      );

  bool get hasImage => activity.hashedImage.imageFilePath != null;

  TextStyle textStyle(BuildContext context) {
    final fontSize = MediaQuery.of(context).orientation == Orientation.portrait
        ? fontSizeFraction(context, fractionOfScreenHeight: 0.02)
        : fontSizeFraction(context, fractionOfScreenHeight: 0.05);
    return TextStyle(
      fontFamily: "Courgette",
      overflow: TextOverflow.ellipsis,
      fontSize: fontSize,
    );
  }

  final Activity activity;
}

class DraggedActivity extends StatefulWidget {
  const DraggedActivity(
      {Key? key,
      required this.draggingKey,
      required this.activity,
      required this.onDragCompleted,
      required this.onDragEnd,
      required this.onDragStarted,
      required this.onDraggableCanceled,
      required this.sizeWhenDragged,
      required this.scrollController})
      : super(key: key);

  final GlobalKey draggingKey;
  final Activity activity;
  final Size sizeWhenDragged;
  final VoidCallback onDragCompleted;
  final void Function(DraggableDetails details) onDragEnd;
  final VoidCallback onDragStarted;
  final void Function(Velocity, Offset) onDraggableCanceled;
  final ScrollController scrollController;

  @override
  State<StatefulWidget> createState() {
    return _DraggedActivityState();
  }
}

class _DraggedActivityState extends State<DraggedActivity>
    with SingleTickerProviderStateMixin {
  bool _isScrolling = false;
  _Direction _scrollDirection = _Direction.down;
  late final Ticker _ticker;
  static const scrollDeltaY = 10.0;

  void startScrolling(_Direction direction) {
    setState(() {
      _isScrolling = true;
      _scrollDirection = direction;
    });
  }

  void stopScrolling() {
    setState(() {
      _isScrolling = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_isScrolling) {
        final delta =
            _scrollDirection == _Direction.down ? scrollDeltaY : -scrollDeltaY;
        //print("Scrolling $_scrollDirection");
        setState(() {
          widget.scrollController.jumpTo(clamp(
              widget.scrollController.offset + delta,
              min: 0.0,
              max: widget.scrollController.position.maxScrollExtent));
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Activity>(
      onDragUpdate: (details) {
        final screenSize = MediaQuery.of(context).size;
        final scrollTreshold = 0.77 * screenSize.height;
        if (details.globalPosition.dy >= scrollTreshold) {
          startScrolling(_Direction.down);
        } else if (details.globalPosition.dy <=
            screenSize.height - scrollTreshold) {
          startScrolling(_Direction.up);
        } else if (_isScrolling) {
          stopScrolling();
        }
      },
      onDragCompleted: widget.onDragCompleted,
      onDragEnd: widget.onDragEnd,
      onDragStarted: widget.onDragStarted,
      onDraggableCanceled: widget.onDraggableCanceled,
      maxSimultaneousDrags: 1,
      childWhenDragging: Container(),
      data: widget.activity,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: SizedBox.fromSize(
        size: widget.sizeWhenDragged,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: ActivityWidget(
            widget.activity,
            key: widget.draggingKey,
          ),
        ),
      ),
      child: ActivityWidget(
        widget.activity,
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Expanded(
  //     child: FractionalTranslation(
  //       translation: const Offset(-0.5, -0.5),
  //       child: ActivityWidget(activity),
  //     ),
  //   );
  // }
}

enum _Direction { up, down }

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

  double floatingAddButtonWidthAndHeight(BuildContext context);
  double floatingAddButtonIconSize(BuildContext context);

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
    return clamp(colorValue, min: 0, max: 255);
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
    //Linearly scale number of activities vertically:
    const maxActivitiesVertically = 6.0;
    const minActivitiesVertically = 2.0;
    const heightAtMinActivities = 80.0;
    const heightAtMaxActivities = 2000.0;
    const slope = (maxActivitiesVertically - minActivitiesVertically) /
        (heightAtMaxActivities - heightAtMinActivities);
    const shift = maxActivitiesVertically - (heightAtMaxActivities * slope);

    final availableHeight = getAvailableHeight(context) - headerHeight(context);
    final numActivitiesVertically = clamp(slope * availableHeight + shift,
        min: minActivitiesVertically, max: maxActivitiesVertically);

    return availableHeight / numActivitiesVertically;
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

  @override
  double floatingAddButtonIconSize(BuildContext context) {
    return pixelsToFontSizeEstimate(
        floatingAddButtonWidthAndHeight(context) * 0.5);
  }

  @override
  double floatingAddButtonWidthAndHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.15;
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
    return addButtonDisabledHeight(context) * 10;
  }

  @override
  double addButtonDisabledHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.005;
  }

  @override
  double addButtonIconSize(BuildContext context) {
    return addButtonDisabledHeight(context) * 5.0;
  }

  @override
  double floatingAddButtonIconSize(BuildContext context) {
    return pixelsToFontSizeEstimate(
        floatingAddButtonWidthAndHeight(context) * 0.5);
  }

  @override
  double floatingAddButtonWidthAndHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.07;
  }
}

String heroTagForActivity({required Activity activity, required int index}) {
  return "${activity.date.toString()}_$index";
}
