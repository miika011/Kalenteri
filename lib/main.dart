import 'package:flutter/material.dart';
import 'package:kalenteri/util.dart';

import 'calendar_view.dart';

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: WeekWidget(),
    ),
  ));
}
