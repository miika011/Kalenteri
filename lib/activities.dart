import 'package:kalenteri/util.dart';

class Activity {
  Activity({required this.timeStamp, required this.label, this.imagePath});

  DateTime timeStamp;
  String label;
  String? imagePath;
}

//Singleton logbook for logging activities
class LogBook {
  static final LogBook _singleton = LogBook._internal();
  LogBook._internal();
  factory LogBook() => _singleton;

  void logActivity(Activity activity) {
    _activities.add(activity);
  }

  List<Activity> activitiesForDay(DateTime day) {
    return _activities
        .where((activity) => activity.timeStamp.isSameDayAs(day))
        .toList();
  }

  final _activities = <Activity>[];
}
