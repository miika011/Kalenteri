import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:image/image.dart' as lib_image;
import 'package:Viikkokalenteri/activities.dart';
import 'package:Viikkokalenteri/util.dart';
import 'package:path_provider/path_provider.dart' as lib_path;
import 'package:crypto/crypto.dart' show md5;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:json_annotation/json_annotation.dart';

/// Handles stored images.
/// Images are accessed via String keys.
class ImageManager {
  static ImageManager _instance = ImageManager._internal();
  static ImageManager get instance {
    return _instance;
  }

  Map<String, SavedImage?> _images = {};

  HashedImage? getImage(String hash) {
    final savedImage = _images[hash];
    if (savedImage == null) {
      return null;
    }
    return HashedImage(type: savedImage.type, imageHash: hash);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("$ImageManager");
    if (jsonString != null) {
      _instance = ImageManager.fromJson(jsonDecode(jsonString));
    }
  }

  static void save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("$ImageManager", jsonEncode(_instance));
    LogBook.save();
  }

  Map<String, dynamic> toJson() {
    final json = {"_images": jsonEncode(_images)};
    return json;
  }

  factory ImageManager.fromJson(Map<String, dynamic> json) {
    final savedImages = jsonDecode(json["_images"]);
    final images = Map<String, SavedImage?>.fromIterable(
      savedImages.entries,
      key: (element) => element.key,
      value: (element) => SavedImage.fromJson(element.value),
    );
    final ret = ImageManager._internal(images: images);

    return ret;
  }

  ImageManager._internal({Map<String, SavedImage?>? images})
      : _images = images ?? {};

  String? getImageFilePath(String imageHash) => _images[imageHash]?.path;

  File? getImageFile(String imageHash) {
    final path = getImageFilePath(imageHash);
    if (path == null) return null;
    return File(path);
  }

  void _addImage(
      {required String hashId,
      required String imagePath,
      required ImageType type}) {
    _images[hashId] = SavedImage(type: type, path: imagePath);
    save();
  }

  /// Stores a smaller resolution image in permanent storage.
  /// Resizes to match the bounds of [screenSize] if the image is larger
  ///  Returns a hash ID for the image or null on error.
  /// Good enough hash function to guarantee unique ID unless the world
  /// ends.
  HashedImage storeResized(
      {required File imageFileToStore, required Size screenSize}) {
    final hashedImage = HashedImage(
        temporaryFilePath: imageFileToStore.path, type: ImageType.storageImage);
    _storeResized(imageFileToStore, screenSize)
        .then((hash) => hashedImage.setImageHash(hash));
    return hashedImage;
  }

  ///Again, disgusting hack but this requires less rewriting
  HashedImage storeAsset(String assetPath) {
    final image = HashedImage(imageHash: assetPath, type: ImageType.assetImage);
    _addImage(
        hashId: assetPath, imagePath: assetPath, type: ImageType.assetImage);
    return image;
  }

  Future<String> _storeResized(File imageFileToStore, Size screenSize) async {
    final outputDirectory = await lib_path.getApplicationDocumentsDirectory();

    final storedImage = await compute(
      _saveResizedWorker,
      _ResizeIsolateArguments(
        oldHashes: _images,
        outputDirectory: outputDirectory,
        imageFile: imageFileToStore,
        screenSize: screenSize,
      ),
    );

    _addImage(
        hashId: storedImage.imageHash!,
        imagePath: storedImage._temporaryImageFilePath!,
        type: ImageType.storageImage);
    return storedImage._imageHash!;
  }

  /// Stores image in permanent storage. Throws on error.
  Future<HashedImage> _saveResizedWorker(_ResizeIsolateArguments args) async {
    final imageFile = args.imageFile,
        screenSize = args.screenSize,
        outputDir = args.outputDirectory,
        oldHashes = args.oldHashes;

    final imageRawData = imageFile.readAsBytesSync();
    final imageHash = md5.convert(imageRawData).toString();
    final String? oldPath = oldHashes[imageHash]?.path;
    if (oldPath != null && File(oldPath).existsSync()) {
      return HashedImage(
          imageHash: imageHash,
          temporaryFilePath: oldPath,
          type: ImageType.storageImage);
    }

    final originalImage = lib_image.decodeImage(imageRawData)!;

    //In case original image is landscape and screen is in portrait
    int width = (originalImage.width >= originalImage.height &&
                screenSize.width >= screenSize.height
            ? screenSize.width
            : screenSize.height)
        .toInt();

    width = min(width, originalImage.width); //Don't upscale small images

    final resizedImage = lib_image.copyResize(
      originalImage,
      width: width,
      height: null, // Don't change aspect ratio
    );
    final resizedImageRawData = _ImageEncoder.encoder.encodeImage(resizedImage);

    File outputFile = File("${outputDir.path}/${_fileNameFor(imageHash)}");
    final resizedImageFile =
        await _saveToStorage(resizedImageRawData, outputFile);
    return HashedImage(
        imageHash: imageHash,
        temporaryFilePath: resizedImageFile.path,
        type: ImageType.storageImage);
  }

  Future<File> _saveToStorage(List<int> imageRawData, File outputFile) async {
    outputFile.writeAsBytesSync(imageRawData, flush: true);
    return outputFile;
  }

  String _fileNameFor(String imageHash) => "$imageHash${_ImageEncoder.suffix}";
}

class SavedImage {
  final ImageType type;
  final String path;

  SavedImage({required this.type, required this.path});

  Map<String, dynamic> toJson() {
    final json = {"type": jsonEncode(type.index), "path": path};
    return json;
  }

  factory SavedImage.fromJson(Map<String, dynamic> json) {
    final ret = SavedImage(
        type: ImageType.values[jsonDecode(json["type"])], path: json["path"]);
    return ret;
  }
}

class _ImageEncoder {
  static const suffix = ".png";
  static final encoder = lib_image.PngEncoder();
}

/// Hashed image that [ImageManager] worker can resize
/// And save quietly in the background
class HashedImage {
  String? _imageHash;
  String? _temporaryImageFilePath;
  ImageType? _imageType;

  String? get imageHash => _imageHash;

  /// Createa a [HashedImage] with
  /// 1)  An already calculated (by [ImageManager])
  ///   hash ID or
  /// 2)  A temporary file path indicating that hashing is still in progress.
  HashedImage(
      {String? imageHash, String? temporaryFilePath, required ImageType type})
      : _imageHash = imageHash,
        _temporaryImageFilePath = temporaryFilePath,
        _imageType = type;

  Map<String, dynamic> toJson() {
    return {
      "imageHash": _imageHash,
      "temporaryPath": _temporaryImageFilePath,
      "imageType": jsonEncode(_imageType)
    };
  }

  factory HashedImage.fromJson(Map<String, dynamic> json) {
    final hash = json["imageHash"];
    final tempPath = json["temporaryPath"];
    final type = ImageType.values[jsonDecode(json["imageType"])];
    final ret = HashedImage(
        imageHash: json["imageHash"],
        temporaryFilePath: json["temporaryPath"],
        type: jsonDecode(json["imageType"]));
    return ret;
  }

  @override
  operator ==(Object other) =>
      other is HashedImage &&
      _imageHash == other._imageHash &&
      _temporaryImageFilePath == other._temporaryImageFilePath;

  @override
  int get hashCode =>
      hashCodeFromObjects([_imageHash, _temporaryImageFilePath]);

  void setImageHash(String newHash) {
    _imageHash = newHash;
    _temporaryImageFilePath = null;
  }

  void setTemporaryFilePath(String temporaryFilePath) {
    _temporaryImageFilePath = temporaryFilePath;
    _imageHash = null;
  }

  String? get _imagePath {
    if (_imageHash == null) return _temporaryImageFilePath;
    return ImageManager.instance.getImageFilePath(_imageHash!);
  }

  ///Disgusting hack with image type
  ///but this required less rewriting for now.
  ImageProvider? get imageProvider {
    final path = _imagePath;
    if (path == null) return null;
    try {
      if (_imageType == ImageType.storageImage) {
        return FileImage(File(path));
      } else if (_imageType == ImageType.assetImage) {
        return Svg(path);
      }
    } catch (e) {}
    return null;
  }
}

enum ImageType { storageImage, assetImage }

class _ResizeIsolateArguments {
  _ResizeIsolateArguments(
      {required this.outputDirectory,
      required this.imageFile,
      required this.oldHashes,
      required this.screenSize});
  File imageFile;
  Directory outputDirectory;
  Size screenSize;
  Map<String, SavedImage?> oldHashes;
}
