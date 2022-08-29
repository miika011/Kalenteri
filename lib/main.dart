import 'package:flutter/material.dart';
import 'package:kalenteri/activities.dart';
import 'package:kalenteri/util.dart';
import 'calendar_view.dart';
import 'image_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogBook.load();
  await ImageManager.load();

  runApp(
    const MaterialApp(
      home: AppHome(),
    ),
  );
}

class AppHome extends StatefulWidget {
  const AppHome({Key? key}) : super(key: key);

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      itemBuilder: (context, index) {
        final dayInTheWeek = pageController.fromIndex(index);
        return WeekWidget(dayInTheWeek);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    pageController = WeekPageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  late final WeekPageController pageController;
}

///Starts from the middle of a signed 32bit integer
///to achieve cheesy bidirectional scrolling.
class WeekPageController extends PageController {
  static const thisWeekPageIndex =
      0x7FFFFFFF >> 1; //Assume signed 32bit for compatibility.

  @override
  int get initialPage => thisWeekPageIndex;

  final now = DateTime.now();

  Date fromIndex(int index) {
    final weeksFromToday = index - initialPage;
    return Date.fromDateTime(
        now.add(Duration(days: DateTime.daysPerWeek * weeksFromToday)));
  }
}
