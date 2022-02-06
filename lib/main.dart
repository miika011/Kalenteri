import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const appName = "CALENDAR";
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appName),
        ),
        body: Center(
            child: TestButton(
          onPressed: () {},
          label: "BUTTON",
          size: TestButtonSize.huge,
        )),
      ),
    );
  }
}

class TestButton extends StatelessWidget {
  const TestButton(
      {Key? key,
      required this.onPressed,
      this.label = "",
      this.size = TestButtonSize.normal})
      : super(key: key);

  final VoidCallback onPressed;
  final String label;
  final TestButtonSize size;

  get width {
    switch (size) {
      case TestButtonSize.small:
        return 75.0;
      case TestButtonSize.normal:
        return 125.0;
      case TestButtonSize.big:
        return 175.0;
      case TestButtonSize.huge:
        return 225.0;
    }
  }

  get height {
    switch (size) {
      case TestButtonSize.small:
        return 25.0;
      case TestButtonSize.normal:
        return 60.0;
      case TestButtonSize.big:
        return 95.0;
      case TestButtonSize.huge:
        return 130.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onPressed,
        child: SizedBox(
          width: width,
          height: height,
          child: Container(
            color: Colors.amber,
            child: Center(
              child: Container(color: Colors.pink, child: Text(label)),
            ),
          ),
        ));
  }
}

enum TestButtonSize { small, normal, big, huge }
