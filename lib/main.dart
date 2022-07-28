import 'package:flutter/material.dart';
import 'calendar_view.dart';

void main() {
  initTestActivities();

  runApp(
    MaterialApp(
      home: WeekWidget(DateTime.now()),
    ),
  );
}
