import 'package:Viikkokalenteri/add_activity/symbols_view/symbols_view.dart';
import 'package:flutter/material.dart';
import 'package:Viikkokalenteri/activities.dart';
import 'package:Viikkokalenteri/util.dart';
import 'package:flutter/services.dart';
import 'calendar_view/calendar_view.dart';
import 'image_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogBook.load();
  await Vocabulary.load();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AppHome(),
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    ),
  );
}

class AppHome extends StatefulWidget {
  const AppHome({Key? key}) : super(key: key);

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  late final WeekPageController pageController;

  ThemeData get themeData => Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(
            const Color.fromARGB(150, 0, 0, 0),
          ),
          thumbVisibility: MaterialStateProperty.all(true),
          thickness: MediaQuery.of(context).orientation == Orientation.landscape
              ? MaterialStateProperty.all(15)
              : MaterialStateProperty.all(5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: themeData,
        child: PageView.builder(
          controller: pageController,
          itemBuilder: (context, index) {
            final dayInTheWeek = pageController.fromIndex(index);
            return WeekWidget(dayInTheWeek);
          },
        ));
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
