import 'package:flutter/material.dart';

class AddActivityWidget extends StatelessWidget {
  const AddActivityWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Text("Add activities"),
      ),
    );
  }
}
