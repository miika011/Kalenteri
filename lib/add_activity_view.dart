import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kalenteri/util.dart';
import 'package:path_provider/path_provider.dart';

import 'activities.dart';
import 'assets.dart';

void nop() {}

final _imagePicker = ImagePicker();

class ActivityTextDialog extends AddActivityPage {
  const ActivityTextDialog(
      {Key? key,
      required Date date,
      required int activityIndex,
      required initialText})
      : super(
            date: date,
            activityIndex: activityIndex,
            key: key,
            initialText: initialText);

  @override
  State<AddActivityPage> createState() {
    return _ActivityTextDialogState();
  }
}

class _ActivityTextDialogState extends _AddActivityPageState {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void onGainedTextFocus() {
    //Don't call super
  }

  @override
  void onPressedCancel() {
    Navigator.of(context).pop();
  }

  @override
  Future<void> popAndReturn() async {
    final activityText = textBoxKey.currentState?.text;
    Navigator.of(context).pop(activityText);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromARGB(223, 255, 255, 255),
      child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPaddingAmount),
          child: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: sizeForAcceptCancelButtons(context).width,
                    height: sizeForAcceptCancelButtons(context).height,
                    child: cancelButton,
                  ),
                ),
                SizedBox(
                  width: sizeForTextBox(context).width,
                  height: sizeForTextBox(context).height,
                  child: textBox(
                      autofocus: true,
                      fontSize: fontSize(context),
                      initialText: widget.initialText),
                ),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: sizeForAcceptCancelButtons(context).width,
                    height: sizeForAcceptCancelButtons(context).height,
                    child: acceptButton,
                  ),
                )
              ],
            ),
          )),
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
    final mq = MediaQuery.of(context);
    final availableHeight =
        max(0, mq.size.height - mq.viewInsets.bottom - mq.viewInsets.top);
    return Size(
        MediaQuery.of(context).size.width * 0.80, availableHeight * 0.75);
  }

  Size sizeForTextBoxPortrait(BuildContext context) {
    final mq = MediaQuery.of(context);
    final availableHeight =
        max(0, mq.size.height - mq.viewInsets.bottom - mq.viewInsets.top);
    return Size(
        MediaQuery.of(context).size.width * 0.55, availableHeight * 0.8);
  }
}

class AddActivityPage extends StatefulWidget {
  const AddActivityPage(
      {Key? key,
      required this.date,
      required this.activityIndex,
      String? initialText})
      : initialText = initialText ?? "",
        super(key: key);

  final Date date;
  final int activityIndex;
  final String initialText;

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  @override
  Widget build(BuildContext context) {
    final addActivityWidget =
        MediaQuery.of(context).orientation == Orientation.portrait
            ? _AddActivityInPortrait(
                date: widget.date,
                pageState: this,
              )
            : _AddActivityInLandscape(date: widget.date, pageState: this);
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: addActivityWidget,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    lateInit();
  }

  void lateInit() {
    imageDisplay = ActivityImageDisplay(
      key: imageDisplayKey,
    );
  }

  void onTextChanged() {
    setState(() {
      //Just update state to force rebuild.
    });
  }

  void onLostTextFocus() {
    setState(() {
      _textHasFocus = false;
    });
  }

  void onGainedTextFocus() {
    setState(() {
      _textHasFocus = true;
    });
    Navigator.push<String>(
      context,
      DialogRoute(
        context: context,
        builder: (context) {
          final previousText = textBoxKey.currentState!.text;
          return ActivityTextDialog(
              activityIndex: widget.activityIndex,
              date: widget.date,
              initialText: previousText);
        },
      ),
    ).then(
      (activityText) {
        if (activityText != null) {
          textBoxKey.currentState!.textController.text = activityText;
        }
      },
    );
    unFocusText();
  }

  AcceptButton get acceptButton {
    return AcceptButton(
      onPressed: onPressedAccept,
      buttonStatus: acceptButtonStatus,
    );
  }

  CancelButton get cancelButton {
    return CancelButton(onPressed: onPressedCancel);
  }

  GalleryButton get galleryButton {
    return GalleryButton(
      onPressed: onPressedGallery,
    );
  }

  CameraButton get cameraButton {
    return CameraButton(
      onPressed: onPressedCamera,
    );
  }

  AcceptButtonStatus get acceptButtonStatus {
    if (hasText || hasImage) {
      if (_textHasFocus) {
        return AcceptButtonStatus.acceptText;
      }
      return AcceptButtonStatus.acceptAndReturn;
    }
    return AcceptButtonStatus.disabled;
  }

  bool get hasText {
    return textBoxKey.currentState != null &&
        textBoxKey.currentState!.text.isNotEmpty;
  }

  bool get hasImage {
    return imageDisplayKey.currentState != null &&
        imageDisplayKey.currentState!.image != null;
  }

  final textBoxKey = GlobalKey<_ActivityTextBoxState>();

  Widget textBox(
      {required double fontSize, String? initialText, bool? autofocus}) {
    return Hero(
      tag: "textBox",
      child: ActivityTextBox(
        key: textBoxKey,
        initialText: initialText,
        autofocus: autofocus,
        onGainedFocus: onGainedTextFocus,
        onLostFocus: onLostTextFocus,
        onTextChanged: onTextChanged,
        fontSize: fontSize,
      ),
    );
  }

  bool _textHasFocus = false;

  final imageDisplayKey = GlobalKey<_ActivityImageDisplayState>();
  late final ActivityImageDisplay imageDisplay;

  void onPressedAccept() async {
    switch (acceptButtonStatus) {

      //Close keyboard if it's open by hitting the accept button
      case AcceptButtonStatus.disabled:
      case AcceptButtonStatus.acceptText:
        unFocusText();
        break;
      case AcceptButtonStatus.acceptAndReturn:
        await popAndReturn();
        break;
    }
  }

  void unFocusText() => setState(() {
        _textHasFocus = false;
        textBoxKey.currentState?.focusNode.unfocus();
      });

  Future<void> popAndReturn() async {
    final File? imageFile = getImageFile();
    final String activityDescription = getActivityDescription();
    if (imageFile != null || activityDescription.isNotEmpty) {
      final persistentDir = await getApplicationDocumentsDirectory();
      final persistentPath =
          "${persistentDir.path}/activity_${widget.activityIndex}_${widget.date.year}_${widget.date.month}_${widget.date.day}.jpg";
      final persistentFile = imageFile?.copySync(persistentPath);
      final Activity activity = Activity(
          date: widget.date,
          text: activityDescription,
          imageFile: persistentFile);
      if (mounted) {
        Navigator.of(context).pop(activity);
      }
    }
  }

  void onPressedCancel() {
    if (!mounted) {
      return;
    }

    if (_textHasFocus) {
      unFocusText();
    } else if (hasText) {
      clearText();
    } else {
      Navigator.of(context).pop();
    }
  }

  void clearText() {
    setState(() {
      textBoxKey.currentState!.textController.clear();
    });
  }

  void onPressedGallery() async {
    final XFile? file =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => imageDisplayKey.currentState!.setImage(File(file.path)));
    }
  }

  void onPressedCamera() async {
    final XFile? file =
        await _imagePicker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() => imageDisplayKey.currentState!.setImage(File(file.path)));
    }
  }

  File? getImageFile() {
    if (imageDisplayKey.currentState == null) return null;
    return (imageDisplayKey.currentState!._image);
  }

  String getActivityDescription() {
    return textBoxKey.currentState!.text;
  }
}

class _AddActivityInPortrait extends StatelessWidget {
  const _AddActivityInPortrait({
    Key? key,
    required this.date,
    required _AddActivityPageState pageState,
  })  : _pageState = pageState,
        super(key: key);

  final Date date;
  final _AddActivityPageState _pageState;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Padding(
              padding: paddingForImage(context),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: widthForImage(context),
                  height: heightForImage(context),
                  child: _pageState.imageDisplay,
                ),
              ),
            ),
            DateWidget(
              date: date,
              fontSize: fontSizeForDate(context),
            ),
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
                        child: _pageState.cancelButton,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: paddingForActivityTextBox(context),
                      child: SizedBox(
                        width: widthForActivityTextBox(context),
                        child: _pageState.textBox(
                          fontSize: pixelsToFontSizeEstimate(
                              MediaQuery.of(context).size.height * 0.03),
                        ),
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
                        child: _pageState.acceptButton,
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
                        child: _pageState.cameraButton),
                  ),
                  Padding(
                    padding: paddingForGalleryButton(context),
                    child: SizedBox(
                        width: sizeForCameraAndGalleryButtons(context).width,
                        height: sizeForCameraAndGalleryButtons(context).height,
                        child: _pageState.galleryButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
  const _AddActivityInLandscape(
      {Key? key, required this.date, required this.pageState})
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
            child: pageState.cancelButton,
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
                  child: pageState.imageDisplay,
                )),
            DateWidget(
                date: date,
                fontSize: MediaQuery.of(context).size.height * 0.065),
            Row(
              children: [
                Padding(
                  padding: paddingForTextBox(context),
                  child: SizedBox(
                    width: sizeForTextBox(context).width,
                    height: sizeForTextBox(context).height,
                    child: pageState.textBox(
                        fontSize: MediaQuery.of(context).size.height * 0.06),
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                        width: sizeForGalleryCameraButtons(context).width,
                        height: sizeForGalleryCameraButtons(context).height,
                        child: pageState.galleryButton),
                    SizedBox(
                        width: sizeForGalleryCameraButtons(context).width,
                        height: sizeForGalleryCameraButtons(context).height,
                        child: pageState.cameraButton)
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
            child: pageState.acceptButton,
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

  final Date date;
  final _AddActivityPageState pageState;
}

class DateWidget extends StatelessWidget {
  const DateWidget({
    Key? key,
    required this.date,
    required this.fontSize,
  }) : super(key: key);

  final Date date;
  final double fontSize;

  Color get backgroundColor => backgroundColorForHeader(date).withAlpha(128);

  Decoration get decoration => BoxDecoration(
      color: backgroundColor, borderRadius: BorderRadius.circular(10));

  TextStyle style(BuildContext context) {
    return GoogleFonts.getFont("Cabin Sketch", fontSize: fontSize);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      child: Text(
        "${date.abbreviatedWeekDay} ${date.toDMY()}",
        textAlign: TextAlign.center,
        style: style(context),
      ),
    );
  }
}

class GalleryButton extends StatelessWidget {
  const GalleryButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decorationForButtons(context: context),
      child: FittedBox(
        fit: BoxFit.cover,
        child: IconButton(
          icon: const Icon(Icons.photo_library),
          onPressed: onPressed,
        ),
      ),
    );
  }

  final VoidCallback onPressed;
}

class CameraButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CameraButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decorationForButtons(context: context),
      child: FittedBox(
        fit: BoxFit.cover,
        child: IconButton(
          icon: const Icon(Icons.photo_camera),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class AcceptButton extends StatelessWidget {
  const AcceptButton(
      {Key? key, required this.onPressed, required this.buttonStatus})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decorationForButtons(context: context),
      child: FittedBox(
        fit: BoxFit.cover,
        child: IconButton(
          icon: icon,
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget get icon {
    switch (buttonStatus) {
      case AcceptButtonStatus.acceptAndReturn:
        return Assets.SVG.done_solid(color);
      case AcceptButtonStatus.disabled:
      case AcceptButtonStatus.acceptText:
        return Assets.SVG.done_outlined(color);
    }
  }

  MaterialColor get color =>
      buttonStatus != AcceptButtonStatus.disabled ? Colors.green : Colors.grey;

  final VoidCallback onPressed;
  final AcceptButtonStatus buttonStatus;
}

enum AcceptButtonStatus { disabled, acceptText, acceptAndReturn }

class ActivityTextBox extends StatefulWidget {
  const ActivityTextBox(
      {Key? key,
      String? initialText,
      required this.onGainedFocus,
      required this.onLostFocus,
      required this.onTextChanged,
      required this.fontSize,
      bool? autofocus})
      : autofocus = autofocus ?? false,
        initialText = initialText ?? "",
        super(key: key);

  final VoidCallback onGainedFocus;
  final VoidCallback onLostFocus;
  final VoidCallback onTextChanged;
  final double fontSize;
  final bool autofocus;
  final String initialText;

  @override
  State<ActivityTextBox> createState() => _ActivityTextBoxState();
}

class _ActivityTextBoxState extends State<ActivityTextBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration(context),
      child: TextField(
        autofocus: widget.autofocus,
        textCapitalization: TextCapitalization.sentences,
        focusNode: focusNode,
        controller: textController,
        style: TextStyle(fontSize: widget.fontSize),
        maxLines: 5,
        decoration: InputDecoration(
            hintText: activityTextInputHint, border: InputBorder.none),
      ),
    );
  }

  String get activityTextInputHint => "Mitä teit?";

  BoxDecoration decoration(BuildContext context) {
    return BoxDecoration(
      border: Border.all(width: 1.5),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(25, 0, 0, 0),
          blurRadius: 5,
          spreadRadius: 5,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(focusChanged);
    textController = TextEditingController(text: widget.initialText);
    textController.addListener(widget.onTextChanged);
  }

  @override
  void dispose() {
    focusNode.removeListener(focusChanged);
    textController.dispose();
    super.dispose();
  }

  String get text {
    return textController.text;
  }

  void focusChanged() {
    if (_hasFocus != focusNode.hasFocus) {
      _hasFocus = focusNode.hasFocus;
      _hasFocus ? widget.onGainedFocus() : widget.onLostFocus();
    }
  }

  bool _hasFocus = false;
  final focusNode = FocusNode();
  late final TextEditingController textController;
}

class CancelButton extends StatelessWidget {
  const CancelButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decorationForButtons(context: context),
      child: FittedBox(
          fit: BoxFit.cover,
          child: IconButton(
            color: Colors.red,
            highlightColor: const Color.fromARGB(99, 250, 0, 0),
            icon: const Icon(Icons.cancel),
            onPressed: onPressed,
          )),
    );
  }

  final VoidCallback onPressed;
}

Decoration decorationForButtons({required BuildContext context}) {
  return const ShapeDecoration(
    shape: CircleBorder(side: BorderSide.none),
    color: Color.fromARGB(25, 0, 0, 0),
  );
}

class ActivityImageDisplay extends StatefulWidget {
  const ActivityImageDisplay({Key? key}) : super(key: key);

  @override
  State<ActivityImageDisplay> createState() => _ActivityImageDisplayState();
}

class _ActivityImageDisplayState extends State<ActivityImageDisplay> {
  @override
  Widget build(BuildContext context) {
    return Material(
        borderRadius: BorderRadius.circular(15),
        elevation: 10,
        child: imageWidget());
  }

  BoxDecoration decoration(BuildContext context) {
    return BoxDecoration(
      border: Border.all(color: Colors.black, width: 4.0),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(35, 0, 0, 0),
          spreadRadius: 5,
          blurRadius: 5,
        )
      ],
    );
  }

  Widget imageWidget() => _image != null
      ? Image(image: FileImage(_image!))
      : const FittedBox(
          fit: BoxFit.fitHeight,
          child: Icon(
            Icons.question_mark_rounded,
            color: Color.fromARGB(59, 158, 158, 158),
          ));

  void setImage(File imageFile) {
    setState(
      () {
        _image = imageFile;
      },
    );
  }

  File? get image => _image;

  File? _image;
}
