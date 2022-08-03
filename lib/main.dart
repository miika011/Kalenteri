import 'package:flutter/material.dart';
import 'package:kalenteri/activities.dart';
import 'package:kalenteri/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calendar_view.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogBook.load();
  runApp(
    MaterialApp(
      home: WeekWidget(DateTime.now()),
    ),
  );
}
