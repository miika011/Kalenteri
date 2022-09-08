import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kalenteri/image_manager.dart';
import 'package:kalenteri/util.dart';

import '../activities.dart';
import 'add_activity_controller.dart';
import 'page_styles.dart';

class ActivityPageReturnParameters {
  ActivityPageReturnParameters({this.activityText});

  String? activityText;
  Future<String>? imageHash;
}

//TODO: Docs
class AddActivityPage extends StatefulWidget {
  const AddActivityPage({Key? key, required this.date, this.oldActivity})
      : super(key: key);

  final Date date;
  final Activity? oldActivity;

  static Future<Activity?> addNewActivity(
      {required Date date,
      required int index,
      required BuildContext context}) async {
    final activity =
        await addOrEditActivity(date: date, index: index, context: context);
    if (activity != null) {
      saveActivityToLogBook(
          newActivity: activity,
          index: index,
          logFunction: LogBook().logActivity);
    }
    return activity;
  }

  static Future<Activity?> editActivity(
      {required Date date,
      required int index,
      required Activity oldActivity,
      required BuildContext context}) async {
    final activity = await addOrEditActivity(
        date: date, index: index, context: context, oldActivity: oldActivity);
    if (activity != null) {
      saveActivityToLogBook(
          newActivity: activity,
          index: index,
          logFunction: LogBook().setActivity);
    }
    return activity;
  }

  static Future<Activity?> addOrEditActivity(
      {required Date date,
      required int index,
      required BuildContext context,
      Activity? oldActivity}) async {
    final newActivity = await Navigator.push<Activity?>(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityPage(
          date: date,
          oldActivity: oldActivity,
        ),
      ),
    );
    return newActivity;
  }

  static Future<void> saveActivityToLogBook(
      {required Activity newActivity,
      required int index,
      required void Function({required Activity activity, required int index})
          logFunction}) async {
    logFunction(activity: newActivity, index: index);
    await newActivity.hashedImage.futureHash;
    LogBook.save();
  }

  @override
  State<StatefulWidget> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return _AddActivityInPortrait(
                  date: widget.date, logicController: logicController);
            } else {
              return _AddActivityInLandscape(
                  date: widget.date, logicController: logicController);
            }
          },
        ),
      ),
    );
  }

  late final logicController =
      AddActivityController(date: widget.date, oldActivity: widget.oldActivity);
}

class _AddActivityInPortrait extends StatelessWidget {
  const _AddActivityInPortrait(
      {Key? key, required this.date, required this.logicController})
      : super(key: key);

  final Date date;
  final AddActivityController logicController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: paddingForImage(context),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: widthForImage(context),
              height: heightForImage(context),
              child: logicController.imageDisplay,
            ),
          ),
        ),
        logicController.dateWidget(date,
            textStyle: TextStyle(
                fontSize:
                    fontSizeFraction(context, fractionOfScreenHeight: 0.05))),
        Padding(
          padding: paddingForSecondRow(context),
          child: Row(
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: paddingForCancelButton(context),
                  child: SizedBox(
                    width: sizeForCancelAcceptButtons(context).width,
                    height: sizeForCancelAcceptButtons(context).height,
                    child: logicController.cancelButton,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: paddingForActivityTextBox(context),
                  child: SizedBox(
                    width: widthForActivityTextBox(context),
                    child: logicController.textBox,
                  ),
                ),
              ),
              Padding(
                padding: paddingForAcceptButton(context),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: sizeForCancelAcceptButtons(context).width,
                    height: sizeForCancelAcceptButtons(context).height,
                    child: logicController.acceptButton,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: paddingForThirdRow(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: paddingForCameraButton(context),
                child: SizedBox(
                    width: sizeForCameraAndGalleryButtons(context).width,
                    height: sizeForCameraAndGalleryButtons(context).height,
                    child: logicController.cameraButton),
              ),
              Padding(
                padding: paddingForGalleryButton(context),
                child: SizedBox(
                    width: sizeForCameraAndGalleryButtons(context).width,
                    height: sizeForCameraAndGalleryButtons(context).height,
                    child: logicController.galleryButton),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double fontSizeForDate(BuildContext context) =>
      MediaQuery.of(context).size.height * 0.05;

  Size sizeForCameraAndGalleryButtons(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.2;
    return Size(width, width);
  }

  double get elevationForImageDisplay => 12.0;

  EdgeInsets paddingForImage(BuildContext context) {
    return EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01);
  }

  double widthForImage(context) {
    return 0.75 * MediaQuery.of(context).size.width;
  }

  EdgeInsets paddingForSecondRow(BuildContext context) {
    return EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.05);
  }

  Size sizeForCancelAcceptButtons(context) {
    final height = 0.2 * MediaQuery.of(context).size.width;
    final width = height;
    return Size(width, height);
  }

  EdgeInsets paddingForCancelButton(BuildContext context) {
    return EdgeInsets.only(
      left: buttonRelativePaddingAmount(context),
    );
  }

  EdgeInsets paddingForCameraButton(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return EdgeInsets.symmetric(horizontal: size.width * 0.025);
  }

  double widthForActivityTextBox(BuildContext context) {
    return 0.70 * MediaQuery.of(context).size.width;
  }

  EdgeInsets paddingForActivityTextBox(BuildContext context) {
    return EdgeInsets.symmetric(
        horizontal: 0.05 * MediaQuery.of(context).size.width);
  }

  EdgeInsets paddingForAcceptButton(BuildContext context) {
    return EdgeInsets.only(right: buttonRelativePaddingAmount(context));
  }

  double buttonRelativePaddingAmount(BuildContext context) {
    return 0.01 * MediaQuery.of(context).size.width;
  }

  double heightForImage(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.3;
  }

  EdgeInsets paddingForThirdRow(BuildContext context) {
    return EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.07);
  }

  EdgeInsets paddingForGalleryButton(BuildContext context) {
    return paddingForCameraButton(context);
  }
}

class _AddActivityInLandscape extends StatelessWidget {
  final Date date;
  final AddActivityController logicController;

  const _AddActivityInLandscape(
      {Key? key, required this.date, required this.logicController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(
              right: horizontalPaddingForAcceptCancelButtons(context),
              bottom: verticalPaddingForAcceptCancelButtons(context)),
          child: SizedBox(
            width: sizeForAcceptCancelButtons(context).width,
            height: sizeForAcceptCancelButtons(context).height,
            child: logicController.cancelButton,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
                padding: paddingForImageDisplay(context),
                child: SizedBox(
                  width: sizeForImageDisplay(context).width,
                  height: sizeForImageDisplay(context).height,
                  child: logicController.imageDisplay,
                )),
            logicController.dateWidget(date,
                textStyle: TextStyle(
                    fontSize: pixelsToFontSizeEstimate(
                        MediaQuery.of(context).size.height * 0.1))),
            Row(
              children: [
                Padding(
                  padding: paddingForTextBox(context),
                  child: SizedBox(
                    width: sizeForTextBox(context).width,
                    height: sizeForTextBox(context).height,
                    child: logicController.textBox,
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                        width: sizeForGalleryCameraButtons(context).width,
                        height: sizeForGalleryCameraButtons(context).height,
                        child: logicController.galleryButton),
                    SizedBox(
                        width: sizeForGalleryCameraButtons(context).width,
                        height: sizeForGalleryCameraButtons(context).height,
                        child: logicController.cameraButton)
                  ],
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
              left: horizontalPaddingForAcceptCancelButtons(context),
              bottom: verticalPaddingForAcceptCancelButtons(context)),
          child: SizedBox(
            width: sizeForAcceptCancelButtons(context).width,
            height: sizeForAcceptCancelButtons(context).height,
            child: logicController.acceptButton,
          ),
        ),
      ],
    );
  }

  EdgeInsets paddingForImageDisplay(BuildContext context) {
    return EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01);
  }

  EdgeInsets paddingForTextBox(BuildContext context) {
    final verticalPaddingAmount = MediaQuery.of(context).size.height * 0.01;
    return EdgeInsets.only(
        top: verticalPaddingAmount,
        bottom: verticalPaddingAmount,
        left: sizeForGalleryCameraButtons(context).width);
  }

  Size sizeForGalleryCameraButtons(BuildContext context) {
    final widthAndHeight = MediaQuery.of(context).size.width * 0.08;
    return Size(widthAndHeight, widthAndHeight);
  }

  Size sizeForImageDisplay(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const aspectRatio = 16.0 / 9.0;
    final height = screenSize.height * 0.45;
    return Size(height * aspectRatio, height);
  }

  double verticalPaddingForAcceptCancelButtons(BuildContext context) =>
      MediaQuery.of(context).size.height * 0.4;

  double horizontalPaddingForAcceptCancelButtons(BuildContext context) =>
      0; //MediaQuery.of(context).size.width * 0.04;

  Size sizeForTextBox(BuildContext context) => Size(
      MediaQuery.of(context).size.width * 0.44,
      MediaQuery.of(context).size.height * 0.35);

  Size sizeForAcceptCancelButtons(BuildContext context) {
    final widthAndHeight = MediaQuery.of(context).size.height * 0.225;
    return Size(widthAndHeight, widthAndHeight);
  }
}

class ActivityTextDialog extends StatelessWidget {
  final Date date;
  late final TextDialogController logicController;

  ActivityTextDialog({Key? key, required this.date, String? initialText})
      : super(key: key) {
    logicController = TextDialogController(
        date: date, oldActivity: Activity(date: date, text: initialText));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Material(
          color: const Color.fromARGB(223, 255, 255, 255),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPaddingAmount),
            child: SingleChildScrollView(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: SizedBox(
                      width: sizeForAcceptCancelButtons(context).width,
                      height: sizeForAcceptCancelButtons(context).height,
                      child: logicController.cancelButton,
                    ),
                  ),
                  SizedBox(
                    width: sizeForTextBox(context).width,
                    height: sizeForTextBox(context).height,
                    child: logicController.textBox,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: sizeForAcceptCancelButtons(context).width,
                      height: sizeForAcceptCancelButtons(context).height,
                      child: logicController.acceptButton,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double get verticalPaddingAmount => 10;

  Size sizeForAcceptCancelButtons(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return sizeForAcceptCancelButtonsPortrait(context);
    } else {
      return sizeForAcceptCancelButtonsLandscape(context);
    }
  }

  Size sizeForAcceptCancelButtonsPortrait(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.2;
    final height = width;
    return Size(width, height);
  }

  Size sizeForAcceptCancelButtonsLandscape(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.1;
    final height = width;
    return Size(width, height);
  }

  double fontSize(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return pixelsToFontSizeEstimate(screenHeight * 0.05);
    } else {
      return pixelsToFontSizeEstimate(screenHeight * 0.08);
    }
  }

  Size sizeForTextBox(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return sizeForTextBoxPortrait(context);
    } else {
      return sizeForTextBoxLandscape(context);
    }
  }

  Size sizeForTextBoxLandscape(BuildContext context) {
    final availableHeight = getAvailableHeight(context);
    return Size(
        MediaQuery.of(context).size.width * 0.80, availableHeight * 0.75);
  }

  Size sizeForTextBoxPortrait(BuildContext context) {
    return Size(MediaQuery.of(context).size.width * 0.55,
        MediaQuery.of(context).size.height * 0.5);
  }

  double getAvailableHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final availableHeight =
        max(0.0, mq.size.height - mq.viewInsets.bottom - mq.viewInsets.top);
    return availableHeight;
  }
}
