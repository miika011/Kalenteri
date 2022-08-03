import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kalenteri/util.dart';
import 'package:path_provider/path_provider.dart';

import 'activities.dart';

final _imagePicker = ImagePicker();

class AddActivityWidget extends StatefulWidget {
  const AddActivityWidget(
      {Key? key, required this.date, required this.activityIndex})
      : super(key: key);

  @override
  State<AddActivityWidget> createState() => _AddActivityWidgetState();

  final Date date;
  final int activityIndex;
}

class _AddActivityWidgetState extends State<AddActivityWidget> {
  @override
  Widget build(BuildContext context) {
    return buildForPortrait(context);
  }

  Widget buildForPortrait(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        Column(
          children: [
            Padding(
              padding: paddingForImage(context),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: widthForImage(context),
                  height: heightForImage(context),
                  child: ActivityImageDisplay(
                    key: _imageDisplayKey,
                  ),
                ),
              ),
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
                        child: CancelButton(
                          iconSize: iconSizeForCancelButton(context),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: paddingForActivityTextBox(context),
                      child: SizedBox(
                        width: widthForActivityTextBox(context),
                        child: ActivityTextBox(
                          key: _activityTextKey,
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
                        child: AcceptButton(
                          iconSize: iconSizeForAcceptButton(context),
                          onPressed: (() async {
                            final File? imageFile =
                                _imageDisplayKey.currentState!.image;
                            final String activityDescription =
                                _activityTextKey.currentState!.text;
                            if (imageFile != null ||
                                activityDescription.isNotEmpty) {
                              final persistentDir =
                                  await getApplicationDocumentsDirectory();
                              final persistentPath =
                                  "${persistentDir.path}/activity_${widget.activityIndex}_${widget.date.year}_${widget.date.month}_${widget.date.day}.jpg";
                              final persistentFile =
                                  imageFile?.copySync(persistentPath);
                              final Activity activity = Activity(
                                  date: widget.date,
                                  label: activityDescription,
                                  imageFile: persistentFile);
                              if (mounted) {
                                Navigator.of(context).pop(activity);
                              }
                            }
                          }),
                        ),
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
                    child: TakePictureButton(
                      onPressed: () async {
                        final XFile? file = await _imagePicker.pickImage(
                            source: ImageSource.camera);
                        if (file != null) {
                          _imageDisplayKey.currentState!
                              .setImage(File(file.path));
                        }
                      },
                      iconSize: iconSizeForCameraButton(context),
                    ),
                  ),
                  Padding(
                      padding: paddingForGalleryButton(context),
                      child: SelectFromGalleryButton(
                        onPressed: () async {
                          final XFile? file = await _imagePicker.pickImage(
                              source: ImageSource.gallery);
                          if (file != null) {
                            _imageDisplayKey.currentState!
                                .setImage(File(file.path));
                          }
                        },
                        iconSize: iconSizeForGalleryButton(context),
                      )),
                ],
              ),
            ),
          ],
        ),
      ]),
    ));
  }

  EdgeInsets paddingForImage(BuildContext context) {
    return EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01);
  }

  double widthForImage(context) {
    return 0.75 * MediaQuery.of(context).size.width;
  }

  EdgeInsets paddingForSecondRow(BuildContext context) {
    return EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.1);
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

  paddingForActivityTextBox(BuildContext context) {
    return EdgeInsets.symmetric(
        horizontal: 0.05 * MediaQuery.of(context).size.width);
  }

  paddingForAcceptButton(BuildContext context) {
    return EdgeInsets.only(right: buttonRelativePaddingAmount(context));
  }

  buttonRelativePaddingAmount(BuildContext context) {
    return 0.01 * MediaQuery.of(context).size.width;
  }

  String get activityLabel {
    return _activityTextKey.currentState!.text;
  }

  final GlobalKey<_ActivityTextBoxState> _activityTextKey = GlobalKey();
  final GlobalKey<_ActivityImageDisplayState> _imageDisplayKey = GlobalKey();

  double heightForImage(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.3;
  }

  EdgeInsets paddingForThirdRow(BuildContext context) {
    return EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.07);
  }

  iconSizeForCameraButton(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.10;
  }

  iconSizeForCancelButton(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.1;
  }

  iconSizeForAcceptButton(BuildContext context) {
    return iconSizeForCancelButton(context);
  }

  iconSizeForGalleryButton(BuildContext context) {
    return iconSizeForCameraButton(context);
  }

  paddingForGalleryButton(BuildContext context) {
    return paddingForCameraButton(context);
  }
}

class SelectFromGalleryButton extends StatelessWidget {
  final double iconSize;

  const SelectFromGalleryButton(
      {Key? key, required this.iconSize, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: decorationForButtons(context: context, radius: iconSize),
        child: IconButton(
          iconSize: iconSize,
          icon: const Icon(Icons.photo_library),
          onPressed: onPressed,
        ));
  }

  final VoidCallback onPressed;
}

class TakePictureButton extends StatelessWidget {
  final double iconSize;

  final VoidCallback onPressed;

  const TakePictureButton(
      {Key? key, required this.iconSize, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: decorationForButtons(context: context, radius: iconSize),
        child: IconButton(
            iconSize: iconSize,
            icon: const Icon(Icons.photo_camera),
            onPressed: onPressed));
  }
}

class AcceptButton extends StatelessWidget {
  final double iconSize;

  const AcceptButton(
      {Key? key, required this.onPressed, required this.iconSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decorationForButtons(context: context, radius: iconSize),
      child: IconButton(
        iconSize: iconSize, color: Colors.green,
        icon: const Icon(Icons.done_outline),
        //color: Colors.green,
        onPressed: onPressed,
      ),
    );
  }

  final VoidCallback onPressed;
}

class ActivityTextBox extends StatefulWidget {
  const ActivityTextBox({Key? key}) : super(key: key);

  @override
  State<ActivityTextBox> createState() => _ActivityTextBoxState();
}

class _ActivityTextBoxState extends State<ActivityTextBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration(context),
      child: TextField(
        controller: _textController,
        style: const TextStyle(fontSize: 18),
        maxLines: 5,
        // decoration: const InputDecoration(
        //   border: OutlineInputBorder(),
        // ),
      ),
    );
  }

  BoxDecoration decoration(BuildContext context) {
    return BoxDecoration(
      border: Border.all(width: 3.0),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(35, 0, 0, 0),
          blurRadius: 5,
          spreadRadius: 5,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get text {
    return _textController.text;
  }

  final _textController = TextEditingController();
}

class CancelButton extends StatelessWidget {
  final double iconSize;

  const CancelButton(
      {Key? key, required this.onPressed, required this.iconSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: decorationForButtons(context: context, radius: iconSize),
        child: IconButton(
          iconSize: iconSize,
          color: Colors.red,
          highlightColor: const Color.fromARGB(99, 250, 0, 0),
          icon: const Icon(Icons.cancel),
          onPressed: onPressed,
        ));
  }

  final VoidCallback onPressed;
}

BoxDecoration decorationForButtons(
    {required BuildContext context, required double radius}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: const Color.fromARGB(25, 0, 0, 0),
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
    return Container(
      decoration: decoration(context),
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

  Widget imageWidget() =>
      _image != null ? Image(image: FileImage(_image!)) : Container();

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
