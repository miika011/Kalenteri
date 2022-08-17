import 'package:flutter/material.dart';
import 'package:kalenteri/activities.dart';
import 'package:kalenteri/util.dart';
import 'calendar_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogBook.load();
  runApp(
    MaterialApp(
      home: WeekWidget(Date.fromDateTime(DateTime.now())),
    ),
  );
}
