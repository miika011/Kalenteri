import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kalenteri/image_manager.dart';
import 'package:permission_handler/permission_handler.dart';

import '../activities.dart';
import '../assets.dart';
import '../util.dart';
import 'add_activity_view.dart';

final _imagePicker = ImagePicker();

Decoration decorationForButtons({required BuildContext context}) {
  return const ShapeDecoration(
    shape: CircleBorder(side: BorderSide.none),
    color: Color.fromARGB(25, 0, 0, 0),
  );
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

enum AcceptButtonStatus { disabled, acceptText, acceptAndReturn }

class ActivityImageDisplay extends StatefulWidget {
  final Activity? oldActivity;
  const ActivityImageDisplay({Key? key, this.oldActivity}) : super(key: key);

  @override
  State<ActivityImageDisplay> createState() => _ActivityImageDisplayState();
}

class ActivityTextBox extends StatefulWidget {
  final bool autoFocusText;
  final String? initialText;
  final void Function(BuildContext context) onGainedFocus;

  final void Function(BuildContext context) onLostFocus;
  final void Function(BuildContext context, {String? newValue}) onTextChanged;
  final TextStyle? _textStyle;
  const ActivityTextBox({
    Key? key,
    this.initialText,
    this.autoFocusText = false,
    required this.onGainedFocus,
    required this.onLostFocus,
    required this.onTextChanged,
    TextStyle? textStyle,
  })  : _textStyle = textStyle,
        super(key: key);

  @override
  State<ActivityTextBox> createState() => _ActivityTextBoxState();

  TextStyle? textStyle(BuildContext context) {
    return _textStyle ??
        Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: "Courgette",
            fontSize: fontSizeFraction(context, fractionOfScreenHeight: 0.04));
  }
}

class _ActivityTextBoxState extends State<ActivityTextBox> {
  bool _hadFocusPreviously = false;

  final focusNode = FocusNode();

  late final TextEditingController textController;

  String get activityTextInputHint => "Kerro tapahtumasta:";

  bool get hasFocus => focusNode.hasFocus;

  bool get hasText => text.trim().isNotEmpty;

  String get text {
    return textController.text;
  }

  @override
  void dispose() {
    focusNode.removeListener(focusChanged);
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(focusChanged);
    textController = TextEditingController(text: widget.initialText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration(context),
      child: TextField(
        onChanged: (String? newValue) =>
            widget.onTextChanged(context, newValue: newValue),
        autofocus: widget.autoFocusText,
        textCapitalization: TextCapitalization.sentences,
        focusNode: focusNode,
        controller: textController,
        expands: true,
        minLines: null,
        maxLines: null,
        style: widget.textStyle(context),
        decoration: InputDecoration(
            hintText: activityTextInputHint,
            border: InputBorder.none,
            hintMaxLines: 2),
      ),
    );
  }

  void clearText() {
    setState(() {
      textController.clear();
    });
  }

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

  void focusChanged() {
    if (_hadFocusPreviously != focusNode.hasFocus) {
      setState(() {
        _hadFocusPreviously = focusNode.hasFocus;
        focusNode.hasFocus
            ? widget.onGainedFocus(context)
            : widget.onLostFocus(context);
      });
    }
  }

  void setText(String newValue) => setState(() {
        textController.text = newValue;
      });
  void unFocus() {
    setState(() {
      focusNode.unfocus();
    });
  }
}

class AddActivityController {
  Activity? oldActivity;
  late final GalleryButton galleryButton =
      GalleryButton(onPressed: onPressedGallery);

  late final CameraButton cameraButton =
      CameraButton(key: _cameraButtonKey, onPressed: onPressedCamera);

  late final AcceptButton acceptButton = AcceptButton(
      key: _acceptButtonKey,
      onPressed: onPressedAccept,
      initialButtonStatus: AcceptButtonStatus.disabled);

  late final CancelButton cancelButton =
      CancelButton(onPressed: onPressedCancel);

  late final ActivityImageDisplay imageDisplay = ActivityImageDisplay(
    key: _imageDisplayKey,
    oldActivity: oldActivity,
  );

  final _acceptButtonKey = GlobalKey<_AcceptButtonState>();

  final _imageDisplayKey = GlobalKey<_ActivityImageDisplayState>();

  final _textBoxKey = GlobalKey<_ActivityTextBoxState>();
  final _cameraButtonKey = GlobalKey<_CameraButtonState>();

  final Date date;

  AddActivityController({required this.date, this.oldActivity});

  HashedImage? get hashedImage {
    return _imageDisplayKey.currentState?._hashedImage;
  }

  bool get hasImage => hashedImage?.imageFilePath != null;

  bool get hasText => textValue.trim().isNotEmpty;

  ActivityTextBox get textBox => ActivityTextBox(
        initialText: oldActivity?.text,
        key: _textBoxKey,
        onGainedFocus: onTextFocusGained,
        onLostFocus: onTextFocusLost,
        onTextChanged: onTextChanged,
        autoFocusText: false,
      );

  bool get textHasFocus {
    final textBoxState = _textBoxKey.currentState;
    if (textBoxState == null) return false;
    return textBoxState.hasFocus;
  }

  String get textValue {
    return _textBoxKey.currentState?.text ?? "";
  }

  void clearText() {
    _textBoxKey.currentState!.clearText();
    updateAcceptButtonStatus();
  }

  DateWidget dateWidget(Date date, {TextStyle? textStyle}) {
    return DateWidget(
      date: date,
      textStyle: textStyle,
    );
  }

  Activity getActivity() =>
      Activity(date: date, text: textValue, hashedImage: hashedImage);

  Object? getValue() {
    return getActivity();
  }

  void onPressedAccept(BuildContext context,
      {required AcceptButtonStatus buttonStatus}) {
    switch (_acceptButtonKey.currentState?.buttonStatus) {

      //Close keyboard if it's open by hitting the accept button
      case AcceptButtonStatus.disabled:
      case AcceptButtonStatus.acceptText:
        unFocusText();
        break;
      case AcceptButtonStatus.acceptAndReturn:
        final value = getValue();
        Navigator.of(context).pop(value);
        break;
      default:
        break;
    }
  }

  void onPressedCamera(BuildContext context) {
    askForCameraPermission(context).then(
      (permissionStatus) {
        if (permissionStatus == PermissionStatus.granted) {
          _selectImage(ImageSource.camera);
        } else {
          _cameraButtonKey.currentState!.setEnabled(false);
        }
      },
    );
  }

  Future<PermissionStatus> askForCameraPermission(BuildContext context) async {
    for (int retriesLeft = 1; retriesLeft >= 0; --retriesLeft) {
      final PermissionStatus permissionStatus =
          await Permission.camera.request();
      if (permissionStatus.isGranted || permissionStatus.isLimited) {
        return PermissionStatus.granted;
      } else if (permissionStatus.isDenied) {
        // Asynchronous gap shouldn't matter here
        // ignore: use_build_context_synchronously
        final bool? wantToDeny = await confirmCameraPermissionDialog(context);
        if (wantToDeny != null && wantToDeny) {
          break;
        }
      }
    }
    return PermissionStatus.permanentlyDenied;
  }

  Future<bool?> confirmCameraPermissionDialog(BuildContext context) {
    return showConfirmDialog(
      context: context,
      description: "Sinun on annettava ohjelmalle lupa "
          "käyttää kameraa, jos haluat ottaa kuvia kalenterimerkintöihisi. "
          "Jos et anna ohjelmalle lupaa käyttää kameraa, voit yhä lisätä kuvia galleriasta.",
      acceptWidget: Column(
        children: [
          Stack(
            children: const [
              Icon(Icons.photo_camera),
              Icon(
                Icons.close,
                color: Colors.red,
              ),
            ],
          ),
          const Text("Älä käytä kameraa")
        ],
      ),
      denyWidget: Column(
        children: const [
          Icon(Icons.photo_camera),
          Text(
            "Käytä kameraa",
          )
        ],
      ),
    );
  }

  void onPressedCancel(BuildContext context) {
    if (_textBoxKey.currentState == null) return;

    if (_textBoxKey.currentState!.hasFocus) {
      unFocusText();
    } else {
      Navigator.of(context).pop();
    }
  }

  void onPressedGallery(BuildContext context) async {
    _selectImage(ImageSource.gallery);
  }

  void onTextChanged(BuildContext context, {String? newValue}) {
    updateAcceptButtonStatus();
  }

  void onTextFocusGained(BuildContext context) async {
    unFocusText();

    Navigator.of(context)
        .push<String>(
      MaterialPageRoute(
        builder: (context) =>
            ActivityTextDialog(date: date, initialText: textValue),
      ),
    )
        .then(
      (newText) {
        if (newText != null) setTextValue(newText);
      },
    );
  }

  void onTextFocusLost(BuildContext context) {
    updateAcceptButtonStatus();
  }

  void setAcceptButtonStatus(AcceptButtonStatus buttonStatus) {
    final buttonState = _acceptButtonKey.currentState;
    buttonState?.buttonStatus = buttonStatus;
  }

  void setImage(XFile file) {
    _imageDisplayKey.currentState!.setImage(File(file.path));
    updateAcceptButtonStatus();
  }

  void setTextValue(String newValue) {
    _textBoxKey.currentState?.setText(newValue);
    updateAcceptButtonStatus();
  }

  void unFocusText() {
    _textBoxKey.currentState?.unFocus();
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

  void _selectImage(ImageSource source) async {
    final XFile? xFile = await _imagePicker.pickImage(source: source);
    if (xFile != null) setImage(xFile);
  }
}

class CameraButton extends StatefulWidget {
  final void Function(BuildContext context) onPressed;

  const CameraButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CameraButtonState();
  }
}

class _CameraButtonState extends State<CameraButton> {
  bool _isEnabled = true;

  _CameraButtonState() {
    Permission.camera.isPermanentlyDenied
        .then((isDenied) => _isEnabled = !isDenied);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      //decoration: _isEnabled ? decorationForButtons(context: context) : null,
      child: FittedBox(
        fit: BoxFit.cover,
        child: IconButton(
          //color: _isEnabled ? null : Colors.grey,
          icon: const Icon(Icons.photo_camera),
          onPressed: _isEnabled ? () => widget.onPressed(context) : null,
        ),
      ),
    );
  }

  void setEnabled(bool enabled) {
    if (enabled != _isEnabled) {
      setState(() {
        _isEnabled = enabled;
      });
    }
  }
}

class CancelButton extends StatelessWidget {
  final void Function(BuildContext context) onPressed;

  const CancelButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      //decoration: decorationForButtons(context: context),
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
}

class DateWidget extends StatelessWidget {
  final Date date;

  final BoxDecoration _decoration;
  final TextStyle? textStyle;
  const DateWidget({
    Key? key,
    required this.date,
    BoxDecoration? decoration,
    this.textStyle,
  })  : _decoration = decoration ?? const BoxDecoration(),
        super(key: key);

  Color get backgroundColor => backgroundColorForHeader(date).withAlpha(128);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _decoration.copyWith(color: backgroundColor),
      child: Text(
        "${date.abbreviatedWeekDay} ${date.toDMY()}",
        textAlign: TextAlign.center,
        style: style(context),
      ),
    );
  }

  TextStyle? style(BuildContext context) {
    return (textStyle ?? Theme.of(context).textTheme.caption)
        ?.copyWith(fontFamily: "Cabin Sketch");
  }
}

class GalleryButton extends StatelessWidget {
  final void Function(BuildContext context) onPressed;

  const GalleryButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      //decoration: decorationForButtons(context: context),
      child: FittedBox(
        fit: BoxFit.cover,
        child: IconButton(
          icon: const Icon(Icons.photo_library),
          onPressed: () => onPressed(context),
        ),
      ),
    );
  }
}

class NoActivityImage extends StatelessWidget {
  const NoActivityImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      fit: BoxFit.fitHeight,
      child: Icon(
        Icons.question_mark_rounded,
        color: Color.fromARGB(59, 158, 158, 158),
      ),
    );
  }
}

class TextDialogController extends AddActivityController {
  TextDialogController({required Date date, Activity? oldActivity})
      : super(date: date, oldActivity: oldActivity);

  @override
  Object? getValue() {
    return textValue;
  }

  @override
  void onTextFocusGained(BuildContext context) {
    // Don't call super if super spawns a new instance of this
    updateAcceptButtonStatus();
  }

  @override
  void updateAcceptButtonStatus() {
    if (!textHasFocus) {
      setAcceptButtonStatus(AcceptButtonStatus.acceptAndReturn);
    } else {
      setAcceptButtonStatus(AcceptButtonStatus.acceptText);
    }
  }

  @override
  ActivityTextBox get textBox => ActivityTextBox(
        onGainedFocus: onTextFocusGained,
        onLostFocus: onTextFocusLost,
        onTextChanged: onTextChanged,
        autoFocusText: true,
        initialText: oldActivity?.text,
        key: _textBoxKey,
      );
}

class _AcceptButtonState extends State<AcceptButton> {
  AcceptButtonStatus? _buttonStatus;

  AcceptButtonStatus get buttonStatus =>
      _buttonStatus ?? widget.initialButtonStatus;

  set buttonStatus(AcceptButtonStatus newStatus) {
    if (newStatus != buttonStatus) {
      setState(() {
        _buttonStatus = newStatus;
      });
    }
  }

  MaterialColor get color =>
      buttonStatus != AcceptButtonStatus.disabled ? Colors.green : Colors.grey;

  Widget get icon {
    switch (buttonStatus) {
      case AcceptButtonStatus.acceptAndReturn:
        return Assets.SVG.done_solid(color);
      case AcceptButtonStatus.disabled:
      case AcceptButtonStatus.acceptText:
        return Assets.SVG.done_outlined(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      //decoration: decorationForButtons(context: context),
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
}

class _ActivityImageDisplayState extends State<ActivityImageDisplay> {
  late HashedImage _hashedImage = widget.oldActivity != null
      ? widget.oldActivity!.hashedImage
      : HashedImage();

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

  Widget imageWidget() {
    if (_hashedImage.imageFilePath != null) {
      return Image(image: FileImage(File(_hashedImage.imageFilePath!)));
    } else {
      return const NoActivityImage();
    }
  }

  Center loadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.red,
        backgroundColor: Colors.blue,
        strokeWidth: 5,
      ),
    );
  }

  /// Updates the image and returns a future to a new hash id.
  void setImage(File? imageFile) {
    if (imageFile == null) return;
    setState(() {
      _hashedImage = ImageManager.instance.storeResized(
          imageFileToStore: imageFile, screenSize: MediaQuery.of(context).size);
    });
  }
}
