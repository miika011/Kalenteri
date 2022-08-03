import 'dart:io';
import 'dart:math';

import 'package:kalenteri/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Activity {
  Activity({required this.date, required this.label, this.imageFile});

  factory Activity.fromJson(Map<String, dynamic> json) {
    final date = json["date"];
    final label = json["label"];
    final imageFilePath = json["imageFilePath"];
    final imageFile = imageFilePath != null ? File(imageFilePath) : null;
    return Activity(
        date: Date.fromJson(date), label: label, imageFile: imageFile);
  }

  Map<String, dynamic> toJson() =>
      {"date": date, "label": label, "imageFilePath": imageFile?.path};

  Date date;
  String label;
  File? imageFile;
}

/// Logbook (singleton) for logging activities
class LogBook {
  static LogBook _singleton = LogBook._internal({});
  LogBook._internal(this._activities);

  factory LogBook() => _singleton;

  void logActivity(Activity activity, int index) {
    final activitiesForDay = _activities[activity.date] ??= [];
    index = min(index, activitiesForDay.length);
    _activities[activity.date]!.insert(index, activity);
    _singleton._isUpToDate = false;
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
    for (final k in _activities.entries) {
      json[jsonEncode(k.key.toJson())] = k.value;
    }
    return {"_activities": json};
  }

  static Future<void> load() async {
    if (_singleton._isUpToDate) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("logBook");
    if (jsonString != null) {
      _singleton = LogBook.fromJson(jsonDecode(jsonString));
    }
    _singleton._isUpToDate = true;
  }

  static Future<void> save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final json = _singleton.toJson();
    final jsonString = jsonEncode(json);

    prefs.setString("logBook", jsonString);
    _singleton._isUpToDate = false;
  }

  bool _isUpToDate = false;

  final Map<Date, List<Activity>> _activities;
}
