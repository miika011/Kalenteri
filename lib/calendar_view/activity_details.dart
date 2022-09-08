import 'package:flutter/material.dart';
import 'package:kalenteri/add_activity/add_activity_controller.dart';
import 'package:kalenteri/add_activity/add_activity_view.dart';
import 'package:kalenteri/image_manager.dart';
import 'package:kalenteri/util.dart';
import 'dart:io';

import '../activities.dart';
import 'calendar_view.dart';

class ActivityDetailsWidget extends StatefulWidget {
  final Activity activity;
  final int index;
  const ActivityDetailsWidget(
      {Key? key, required this.activity, required this.index})
      : super(key: key);

  @override
  State<ActivityDetailsWidget> createState() => _ActivityDetailsWidgetState();
}

class _ActivityDetailsWidgetState extends State<ActivityDetailsWidget> {
  late Activity activity;

  @override
  void initState() {
    super.initState();
    activity = widget.activity;
  }

  @override
  Widget build(BuildContext context) {
    Widget image = activity.hashedImage.imageFilePath != null
        ? ActivityDetailsImageWidget(
            imageProvider: FileImage(File(activity.hashedImage.imageFilePath!)))
        : const NoActivityImage();

    return Dialog(
      child: Scaffold(
        appBar: appBar(context),
        body: Column(
          children: [
            Card(
              elevation: 10,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: image,
              ),
            ),
            Card(
              shape: Border.all(style: BorderStyle.none),
              elevation: 10,
              child: DateWidget(
                textStyle: textStyleForDateWidget(context),
                date: activity.date,
              ),
            ),
            Expanded(
              child: ActivityDetailsDescriptionWidget(activity: activity),
            ),
          ],
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    final layout = LayoutForPortrait();
    final appBarBottomHeight = layout.addButtonDisabledHeight(context);

    return AppBar(
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 75, 75, 75)),
      backgroundColor: Colors.white,
      leading: IconButton(
        iconSize: appBarIconSize(),
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          iconSize: appBarIconSize(),
          onPressed: () async {
            final newActivity = await AddActivityPage.editActivity(
              date: activity.date,
              index: widget.index,
              context: context,
              oldActivity: activity,
            );
            if (newActivity != null) {
              setState(
                () {
                  activity = newActivity;
                },
              );
            }
          },
          icon: const Icon(Icons.edit),
        )
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(appBarBottomHeight),
        child: SizedBox(
            height: appBarBottomHeight,
            child: Container(
              decoration: layout.addButtonDecoration,
            )),
      ),
    );
  }

  double appBarIconSize() => AppBar().preferredSize.height * 0.8;

  TextStyle textStyleForDateWidget(BuildContext context) {
    final fontSize = MediaQuery.of(context).orientation == Orientation.portrait
        ? fontSizeFraction(context, fractionOfScreenHeight: 0.06)
        : fontSizeFraction(context, fractionOfScreenHeight: 0.09);
    return TextStyle(fontSize: fontSize);
  }
}

class ActivityDetailsImageWidget extends StatelessWidget {
  final ImageProvider imageProvider;
  const ActivityDetailsImageWidget({Key? key, required this.imageProvider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image(
      image: imageProvider,
    );
  }
}

class ActivityDetailsDescriptionWidget extends StatelessWidget {
  final Activity activity;
  const ActivityDetailsDescriptionWidget({Key? key, required this.activity})
      : super(key: key);

  TextStyle? descriptionTextStyle(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return TextStyle(
          fontSize: fontSizeFraction(context, fractionOfScreenHeight: 0.04));
    } else {
      return TextStyle(
          fontSize: fontSizeFraction(context, fractionOfScreenHeight: 0.1));
    }
  }

  TextStyle dateTextStyle(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return TextStyle(
          fontSize: fontSizeFraction(context, fractionOfScreenHeight: 0.04));
    } else {
      return TextStyle(
          fontSize: fontSizeFraction(context, fractionOfScreenHeight: 0.1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            activity.text,
            style: descriptionTextStyle(context),
          ),
        ),
      ],
    );
  }
}
