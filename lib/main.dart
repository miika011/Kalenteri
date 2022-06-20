import 'package:flutter/material.dart';
import 'calendar_view.dart';

void main() {
  initTestActivities();

  runApp(const MaterialApp(
    home: Scaffold(
      body: WeekWidget(),
    ),
  ));
}
