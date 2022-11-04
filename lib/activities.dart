import 'dart:math';
import 'package:Viikkokalenteri/image_manager.dart';
import 'package:Viikkokalenteri/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Activity {
  Date _date;
  String _text;
  HashedImage? _hashedImage;

  Date get date => _date;
  String get text => _text;
  HashedImage? get hashedImage => _hashedImage;

  Activity({required Date date, String? text, HashedImage? hashedImage})
      : _text = text ?? "",
        _hashedImage = hashedImage,
        _date = date;

  @override
  bool operator ==(Object other) {
    return other is Activity &&
        date == other.date &&
        text == other.text &&
        hashedImage == other.hashedImage;
  }

  @override
  int get hashCode => hashCodeFromObjects([date, text, hashedImage]);

  factory Activity.fromJson(Map<String, dynamic> json) {
    final date = json["date"];
    final label = json["label"];
    final imageHash = json["imageHash"];
    final hashedImage =
        imageHash != null ? ImageManager.instance.getImage(imageHash) : null;
    final ret = Activity(
      date: Date.fromJson(date),
      text: label,
      hashedImage: hashedImage,
    );
    return ret;
  }

  Map<String, dynamic> toJson() =>
      {"date": date, "label": text, "imageHash": _hashedImage?.imageHash};
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

  void addActivity({required Activity activity, required int index}) {
    final activitiesForDay = _getModifiableListOfActivities(activity.date);
    index = min(index, activitiesForDay.length);
    activitiesForDay.insert(index, activity);
    save();
  }

  void deleteActivity({required Date date, required int index}) {
    final activities = _getModifiableListOfActivities(date);
    if (index < activities.length) {
      activities.removeAt(index);
    }
    save();
  }

  ///Throws on invalid index
  void setActivity({required Activity activity, required int index}) {
    _getModifiableListOfActivities(activity.date)[index] = activity;
    save();
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
      for (final activityJson in entry.value) {
        final activity = Activity.fromJson(activityJson);
        if (activity.text.isNotEmpty ||
            activity.hashedImage?.imageHash != null) {
          activitiesForDay.add(activity);
        }
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
    await ImageManager.load();
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
