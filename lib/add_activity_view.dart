import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kalenteri/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as lib_image;

import 'activities.dart';
import 'assets.dart';

final _imagePicker = ImagePicker();

class ActivityTextDialog extends StatelessWidget {
  get acceptButton => null;

  get textBox => null;

  get cancelButton => null;

  static PageStyle pageStyle(
      {required BuildContext context, required String initialText}) {
    final fontSize =
        pixelsToFontSizeEstimate(MediaQuery.of(context).size.height * 0.1);
    return PageStyle(
        autofocusText: false,
        dateWidgetFontSize: fontSize,
        textBoxFontSize: fontSize,
        initialText: initialText);
  }

  const ActivityTextDialog({Key? key}) : super(key: key);

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
                    child: textBox,
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

Activity? activityBuilder(AddActivityPageController controller, Date date) {
  return Activity(
      date: date, imageFile: controller.imageFile, text: controller.textValue);
}

class AddActivityPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final addActivityWidget =
        MediaQuery.of(context).orientation == Orientation.portrait
            ? _AddActivityInPortrait(
                key: UniqueKey(),
                date: date,
                pageController: AddActivityPageController(
                  date: date,
                  pageStyle: _AddActivityInPortrait.pageStyle(context),
                  textBoxKey: GlobalKey(),
                ),
              )
            : _AddActivityInLandscape(
                key: UniqueKey(),
                date: date,
                pageController: AddActivityPageController(
                  textBoxKey: GlobalKey(),
                  date: date,
                  pageStyle: _AddActivityInLandscape.pageStyle(context),
                ),
              );
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: addActivityWidget,
      ),
    );
  }
}

class AddActivityPageController {
  AddActivityPageController(
      {required this.textBoxKey, required this.date, required this.pageStyle}) {
    final k = textBoxKey;
  }

  void onPressedGallery(BuildContext context) async {
    final XFile? file =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setImage(file);
    }
  }

  void onPressedCamera(BuildContext context) async {
    final XFile? file =
        await _imagePicker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setImage(file);
    }
  }

  void setImage(XFile file) {
    _imageDisplayKey.currentState!.setImage(File(file.path));
    updateAcceptButtonStatus();
  }

  void onPressedAccept<T>(BuildContext context,
      {required AcceptButtonStatus buttonStatus}) {
    switch (_acceptButtonKey.currentState?.buttonStatus) {

      //Close keyboard if it's open by hitting the accept button
      case AcceptButtonStatus.disabled:
      case AcceptButtonStatus.acceptText:
        unFocusText();
        break;
      case AcceptButtonStatus.acceptAndReturn:
        final Activity activity = getActivity();
        Navigator.of(context).pop(activity);
        break;
      default:
        break;
    }
  }

  void unFocusText() {
    textBoxKey.currentState?.unFocus();
  }

  void onPressedCancel(BuildContext context) {
    if (textBoxKey.currentState == null) return;

    if (textBoxKey.currentState!.hasFocus) {
      unFocusText();
    } else if (textBoxKey.currentState!.hasText) {
      clearText();
    } else {
      Navigator.of(context).pop();
    }
  }

  void onTextFocus(BuildContext context) async {
    // final newText = await Navigator.of(context).push<String>(MaterialPageRoute(
    //   builder: (context) => const ActivityTextDialog(),
    // ));
    // if (newText != null) {
    //   setTextValue(newText);
    // }
    updateAcceptButtonStatus();
  }

  void onTextFocusLost(BuildContext context) {
    updateAcceptButtonStatus();
  }

  void onTextChanged(BuildContext context, {String? newValue}) {
    updateAcceptButtonStatus();
  }

  void updateAcceptButtonStatus() {
    if (hasText || hasImage) {
      if (textHasFocus) {
        setAcceptButtonStatus(AcceptButtonStatus.acceptText);
      } else {
        setAcceptButtonStatus(AcceptButtonStatus.acceptAndReturn);
      }
    } else {
      setAcceptButtonStatus(AcceptButtonStatus.disabled);
    }
  }

  void setAcceptButtonStatus(AcceptButtonStatus buttonStatus) {
    final buttonState = _acceptButtonKey.currentState;
    buttonState?.buttonStatus = buttonStatus;
  }

  void clearText() {
    textBoxKey.currentState!.clearText();
  }

  bool get textHasFocus {
    final textBoxState = textBoxKey.currentState;
    if (textBoxState == null) return false;
    return textBoxState.hasFocus;
  }

  File? get imageFile {
    return _imageDisplayKey.currentState?._image;
  }

  bool get hasImage => imageFile != null;

  String get textValue {
    return textBoxKey.currentState?.text ?? "";
  }

  void setTextValue(String newValue) =>
      textBoxKey.currentState?.setText(newValue);

  bool get hasText => textValue.trim().isNotEmpty;

  final PageStyle pageStyle;

  DateWidget dateWidget(Date date) {
    return DateWidget(date: date, fontSize: pageStyle.dateWidgetFontSize);
  }

  GalleryButton get galleryButton => GalleryButton(onPressed: onPressedGallery);

  CameraButton get cameraButton => CameraButton(onPressed: onPressedCamera);

  AcceptButton get acceptButton => AcceptButton(
      key: _acceptButtonKey,
      onPressed: onPressedAccept,
      initialButtonStatus: AcceptButtonStatus.disabled);

  CancelButton get cancelButton => CancelButton(onPressed: onPressedCancel);

  ActivityImageDisplay get imageDisplay => ActivityImageDisplay(
        key: _imageDisplayKey,
      );

  ActivityTextBox get textBox => ActivityTextBox(
        key: textBoxKey,
        onGainedFocus: onTextFocus,
        onLostFocus: onTextFocusLost,
        onTextChanged: onTextChanged,
        fontSize: pageStyle.textBoxFontSize,
        initialText: pageStyle.initialText,
        autofocus: pageStyle.autofocusText,
      );

  final _acceptButtonKey = GlobalKey<_AcceptButtonState>();
  final _imageDisplayKey = GlobalKey<_ActivityImageDisplayState>();
  final textBoxKey; // = GlobalKey<_ActivityTextBoxState>();

  final Date date;

  Activity getActivity() {
    return Activity(date: date, text: textValue, imageFile: imageFile);
  }
}

class PageStyle {
  PageStyle({
    required this.dateWidgetFontSize,
    required this.textBoxFontSize,
    required this.autofocusText,
    this.initialText,
  });

  final double dateWidgetFontSize;
  final double textBoxFontSize;
  final String? initialText;
  final bool autofocusText;
}

class _AddActivityInPortrait extends StatelessWidget {
  static PageStyle pageStyle(BuildContext context) {
    return PageStyle(
        autofocusText: false,
        dateWidgetFontSize:
            pixelsToFontSizeEstimate(MediaQuery.of(context).size.height * 0.05),
        textBoxFontSize:
            pixelsToFontSizeEstimate(MediaQuery.of(context).size.height * 0.04),
        initialText: "");
  }

  const _AddActivityInPortrait(
      {Key? key, required this.date, required this.pageController})
      : super(key: key);

  final Date date;
  final AddActivityPageController pageController;

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
                  child: pageController.imageDisplay,
                ),
              ),
            ),
            pageController.dateWidget(date),
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
                        child: pageController.cancelButton,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: paddingForActivityTextBox(context),
                      child: SizedBox(
                        width: widthForActivityTextBox(context),
                        child: pageController.textBox,
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
                        child: pageController.acceptButton,
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
                        child: pageController.cameraButton),
                  ),
                  Padding(
                    padding: paddingForGalleryButton(context),
                    child: SizedBox(
                        width: sizeForCameraAndGalleryButtons(context).width,
                        height: sizeForCameraAndGalleryButtons(context).height,
                        child: pageController.galleryButton),
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
  static PageStyle pageStyle(BuildContext context) {
    return PageStyle(
        dateWidgetFontSize:
            pixelsToFontSizeEstimate(MediaQuery.of(context).size.height * 0.1),
        textBoxFontSize:
            pixelsToFontSizeEstimate(MediaQuery.of(context).size.height * 0.1),
        initialText: "",
        autofocusText: false);
  }

  final Date date;
  final AddActivityPageController pageController;

  const _AddActivityInLandscape(
      {Key? key, required this.date, required this.pageController})
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
            child: pageController.cancelButton,
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
                  child: pageController.imageDisplay,
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
                    child: pageController.textBox,
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                        width: sizeForGalleryCameraButtons(context).width,
                        height: sizeForGalleryCameraButtons(context).height,
                        child: pageController.galleryButton),
                    SizedBox(
                        width: sizeForGalleryCameraButtons(context).width,
                        height: sizeForGalleryCameraButtons(context).height,
                        child: pageController.cameraButton)
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
            child: pageController.acceptButton,
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
    return TextStyle(fontFamily: "Cabin Sketch", fontSize: fontSize);
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
          onPressed: () => onPressed(context),
        ),
      ),
    );
  }

  final void Function(BuildContext context) onPressed;
}

class CameraButton extends StatelessWidget {
  final void Function(BuildContext context) onPressed;

  const CameraButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decorationForButtons(context: context),
      child: FittedBox(
        fit: BoxFit.cover,
        child: IconButton(
          icon: const Icon(Icons.photo_camera),
          onPressed: () => onPressed(context),
        ),
      ),
    );
  }
}

class AcceptButton extends StatefulWidget {
  final AcceptButtonStatus initialButtonStatus;
  final void Function(BuildContext context,
      {required AcceptButtonStatus buttonStatus}) onPressed;

  const AcceptButton(
      {Key? key, required this.onPressed, required this.initialButtonStatus})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AcceptButtonState();
  }
}

class _AcceptButtonState extends State<AcceptButton> {
  AcceptButtonStatus? _buttonStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decorationForButtons(context: context),
      child: FittedBox(
        fit: BoxFit.cover,
        child: IconButton(
          icon: icon,
          onPressed: () =>
              widget.onPressed(context, buttonStatus: buttonStatus),
        ),
      ),
    );
  }

  AcceptButtonStatus get buttonStatus =>
      _buttonStatus ?? widget.initialButtonStatus;

  set buttonStatus(AcceptButtonStatus newStatus) {
    if (newStatus != buttonStatus) {
      setState(() {
        _buttonStatus = newStatus;
      });
    }
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
}

enum AcceptButtonStatus { disabled, acceptText, acceptAndReturn }

class ActivityTextBox extends StatefulWidget {
  const ActivityTextBox(
      {Key? key,
      this.initialText,
      required this.onGainedFocus,
      required this.onLostFocus,
      required this.onTextChanged,
      required this.fontSize,
      bool? autofocus})
      : autofocus = autofocus ?? false,
        super(key: key);

  final void Function(BuildContext context) onGainedFocus;
  final void Function(BuildContext context) onLostFocus;
  final void Function(BuildContext context, {String? newValue}) onTextChanged;
  final double fontSize;
  final bool autofocus;
  final String? initialText;

  @override
  State<ActivityTextBox> createState() => _ActivityTextBoxState();
}

class _ActivityTextBoxState extends State<ActivityTextBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration(context),
      child: TextField(
        onChanged: (String? newValue) =>
            widget.onTextChanged(context, newValue: newValue),
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
  }

  @override
  void dispose() {
    focusNode.removeListener(focusChanged);
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  String get text {
    return textController.text;
  }

  void clearText() {
    setState(() {
      textController.clear();
    });
  }

  void setText(String newValue) => setState(() {
        textController.text = newValue;
      });

  bool get hasText => text.trim().isNotEmpty;

  bool get hasFocus => focusNode.hasFocus;

  void focusChanged() {
    if (_hadFocusPreviously != focusNode.hasFocus) {
      setState(() {
        _hadFocusPreviously = focusNode.hasFocus;
        _hadFocusPreviously
            ? widget.onGainedFocus(context)
            : widget.onLostFocus(context);
      });
    }
  }

  void unFocus() {
    setState(() {
      focusNode.unfocus();
    });
  }

  bool _hadFocusPreviously = false;
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
            onPressed: () => onPressed(context)),
      ),
    );
  }

  final void Function(BuildContext context) onPressed;
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
      child: imageWidget(),
    );
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
      ? Image(
          image: FileImage(_image!),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                color: Colors.red,
                backgroundColor: Colors.blue,
                strokeWidth: 5,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        )
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
  GlobalKey imageKey = GlobalKey();

  File? _image;
}
