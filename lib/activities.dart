import 'dart:math';

import 'package:kalenteri/image_manager.dart';
import 'package:kalenteri/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Activity {
  Date _date;
  String _text;
  HashedImage _hashedImage;

  Activity({required date, String? text, HashedImage? hashedImage})
      : _text = text ?? "",
        _hashedImage = hashedImage ?? HashedImage(),
        _date = date;

  factory Activity.fromJson(Map<String, dynamic> json) {
    final date = json["date"];
    final label = json["label"];
    final imageHash = json["imageHash"];
    return Activity(
        date: Date.fromJson(date),
        text: label,
        hashedImage: HashedImage(imageHash: imageHash));
  }

  Map<String, dynamic> toJson() =>
      {"date": date, "label": text, "imageHash": _hashedImage.imageHash};

  Date get date => _date;
  String get text => _text;
  HashedImage get hashedImage => _hashedImage;
}

/// Logbook for logging activities
class LogBook {
  static LogBook _instance = LogBook._internal({});

  final Map<Date, List<Activity>> _activities;

  LogBook._internal(this._activities);

  factory LogBook() => _instance;

  //TODO: doc
  ///Throws ArgumentError
  void updateActivity(
      Date date, int index, Activity Function(Activity oldActivity) edit) {
    final activities = _getModifiableListOfActivities(date);
    if (index < 0 || activities.length <= index) {
      throw ArgumentError("Activity doesn't exist");
    }
    activities[index] = edit(activities[index]);
  }

  List<Activity> _getModifiableListOfActivities(Date date) =>
      _activities[date] ??= [];

  void logActivity(Activity activity, int index) {
    final activitiesForDay = _getModifiableListOfActivities(activity.date);
    index = min(index, activitiesForDay.length);
    activitiesForDay.insert(index, activity);
  }

  List<Activity> activitiesForDate(Date date) {
    final ret = _activities[date];
    return ret ?? [];
  }

  factory LogBook.fromJson(Map<String, dynamic> json) {
    final Map<Date, List<Activity>> activities = {};
    for (final entry in json["_activities"].entries) {
      final dateJson = jsonDecode(entry.key);
      final date = Date.fromJson(dateJson);
      final List<Activity> activitiesForDay = [];
      for (final act in entry.value) {
        activitiesForDay.add(Activity.fromJson(act));
      }
      activities[date] = activitiesForDay;
    }
    return LogBook._internal(activities);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    for (final entry in _activities.entries) {
      json[jsonEncode(entry.key.toJson())] = entry.value;
    }
    return {"_activities": json};
  }

  static Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("logBook");
    if (jsonString != null) {
      _instance = LogBook.fromJson(jsonDecode(jsonString));
    }
  }

  static Future<void> save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final json = _instance.toJson();
    final jsonString = jsonEncode(json);

    prefs.setString("logBook", jsonString);
  }
}
