import 'package:flutter/material.dart';
import 'package:kalenteri/add_activity/add_activity_controller.dart';
import 'package:kalenteri/add_activity/add_activity_view.dart';
import 'package:kalenteri/util.dart';
import 'dart:io';

import '../activities.dart';

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
  late Activity editableActivity;

  @override
  void initState() {
    super.initState();
    editableActivity = widget.activity;
  }

  @override
  Widget build(BuildContext context) {
    Widget image = editableActivity.hashedImage.imageFilePath != null
        ? ActivityDetailsImageWidget(
            imageProvider:
                FileImage(File(editableActivity.hashedImage.imageFilePath!)))
        : const NoActivityImage();

    return Dialog(
      child: Scaffold(
        appBar: appBar(context),
        body: Column(
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.33,
                child: Card(
                  elevation: 10,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: image,
                  ),
                )),
            Card(
              shape: Border.all(style: BorderStyle.none),
              elevation: 10,
              child: DateWidget(
                textStyle: textStyleForDateWidget(context),
                date: editableActivity.date,
              ),
            ),
            Expanded(
              child: Card(
                color: const Color.fromARGB(255, 240, 240, 240),
                child: ActivityDetailsDescriptionWidget(
                    activity: editableActivity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 75, 75, 75)),
      backgroundColor: backgroundColorForHeader(editableActivity.date),
      leading: _AppBarIcon(
        icon: const Icon(Icons.close),
        iconSize: appBarIconSize(),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        _AppBarIcon(
          icon: const Icon(Icons.delete),
          iconSize: appBarIconSize(),
          onPressed: () async {
            final wantToDelete = await showConfirmDialog(
              context: context,
              description: 'Haluatko poistaa tapahtuman?',
            );
            if (!mounted) return;
            if (wantToDelete ?? false) {
              LogBook().deleteActivity(
                  date: editableActivity.date, index: widget.index);
              Navigator.pop(context);
            }
          },
        ),
        _AppBarIcon(
          icon: const Icon(Icons.edit),
          iconSize: appBarIconSize(),
          onPressed: () async {
            final Activity? newActivity = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddActivityPage(
                  date: editableActivity.date,
                  oldActivity: editableActivity,
                ),
              ),
            );
            if (newActivity != null) {
              setState(
                () {
                  LogBook()
                      .setActivity(activity: newActivity, index: widget.index);
                  editableActivity = newActivity;
                },
              );
            }
          },
        ),
      ],
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

class _AppBarIcon extends StatelessWidget {
  const _AppBarIcon(
      {Key? key,
      required this.icon,
      required this.iconSize,
      required this.onPressed})
      : super(key: key);
  final Icon icon;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitHeight,
      child: IconButton(
        iconSize: iconSize,
        icon: icon,
        onPressed: onPressed,
      ),
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
          fontSize: fontSizeFraction(context, fractionOfScreenHeight: 0.07));
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
          padding: const EdgeInsets.all(5),
          child: Text(
            activity.text,
            style: descriptionTextStyle(context),
          ),
        ),
      ],
    );
  }
}
