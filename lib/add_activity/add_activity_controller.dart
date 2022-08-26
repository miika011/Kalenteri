import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../activities.dart';
import '../assets.dart';
import '../util.dart';
import 'add_activity_view.dart';
import 'page_styles.dart';

final _imagePicker = ImagePicker();

class AddActivityController {
  AddActivityController({required this.date, PageStyle? pageStyle})
      : pageStyle = pageStyle ?? PageStyle();

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
        final Object? value = getValue();
        Navigator.of(context).pop(value);
        break;
      default:
        break;
    }
  }

  void unFocusText() {
    _textBoxKey.currentState?.unFocus();
    updateAcceptButtonStatus();
  }

  void onPressedCancel(BuildContext context) {
    if (_textBoxKey.currentState == null) return;

    if (_textBoxKey.currentState!.hasFocus) {
      unFocusText();
    } else if (_textBoxKey.currentState!.hasText) {
      clearText();
    } else {
      Navigator.of(context).pop();
    }
  }

  void onTextFocus(BuildContext context) {
    Navigator.of(context)
        .push<String>(MaterialPageRoute(
      builder: (context) =>
          ActivityTextDialog(date: date, initialText: textValue),
    ))
        .then((newText) {
      if (newText != null) {
        setTextValue(newText);
      }
    });
    unFocusText();
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
    _textBoxKey.currentState!.clearText();
    updateAcceptButtonStatus();
  }

  bool get textHasFocus {
    final textBoxState = _textBoxKey.currentState;
    if (textBoxState == null) return false;
    return textBoxState.hasFocus;
  }

  File? get imageFile {
    return _imageDisplayKey.currentState?._image;
  }

  bool get hasImage => imageFile != null;

  String get textValue {
    return _textBoxKey.currentState?.text ?? "";
  }

  void setTextValue(String newValue) {
    _textBoxKey.currentState?.setText(newValue);
    updateAcceptButtonStatus();
  }

  bool get hasText => textValue.trim().isNotEmpty;

  PageStyle pageStyle;

  DateWidget dateWidget(Date date) {
    return DateWidget(
      date: date,
      pageStyle: pageStyle,
    );
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
        pageStyle: pageStyle,
        key: _textBoxKey,
        onGainedFocus: onTextFocus,
        onLostFocus: onTextFocusLost,
        onTextChanged: onTextChanged,
      );

  final _acceptButtonKey = GlobalKey<_AcceptButtonState>();
  final _imageDisplayKey = GlobalKey<_ActivityImageDisplayState>();
  final _textBoxKey = GlobalKey<_ActivityTextBoxState>();

  final Date date;

  Object? getValue() {
    return getActivity();
  }

  Activity getActivity() =>
      Activity(date: date, text: textValue, imageFile: imageFile);
}

class TextDialogController extends AddActivityController {
  TextDialogController({required Date date}) : super(date: date);

  @override
  void onTextFocus(BuildContext context) {
    // Don't call super if super spawns a new instance of this
  }

  @override
  Object? getValue() {
    return textValue;
  }

  @override
  PageStyle get pageStyle => PageStyleForTextDialog();
}

class DateWidget extends StatelessWidget {
  DateWidget({Key? key, required this.date, required this.pageStyle})
      : super(key: key);

  final Date date;
  final PageStyle pageStyle;

  Color get backgroundColor => backgroundColorForHeader(date).withAlpha(128);

  Decoration get decoration => BoxDecoration(
      color: backgroundColor, borderRadius: BorderRadius.circular(10));

  TextStyle style(BuildContext context) {
    return TextStyle(
        fontFamily: "Cabin Sketch",
        fontSize: pageStyle.dateWidgetFontSize(context));
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
      required this.onGainedFocus,
      required this.onLostFocus,
      required this.onTextChanged,
      required this.pageStyle})
      : super(key: key);

  final void Function(BuildContext context) onGainedFocus;
  final void Function(BuildContext context) onLostFocus;
  final void Function(BuildContext context, {String? newValue}) onTextChanged;
  final PageStyle pageStyle;

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
        autofocus: widget.pageStyle.autofocusText ?? false,
        textCapitalization: TextCapitalization.sentences,
        focusNode: focusNode,
        controller: textController,
        style: TextStyle(fontSize: widget.pageStyle.textBoxFontSize(context)),
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
    textController = TextEditingController(text: widget.pageStyle.initialText);
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

Decoration decorationForButtons({required BuildContext context}) {
  return const ShapeDecoration(
    shape: CircleBorder(side: BorderSide.none),
    color: Color.fromARGB(25, 0, 0, 0),
  );
}
