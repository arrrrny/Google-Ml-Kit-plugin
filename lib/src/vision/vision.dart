import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

part 'barcode_scanner.dart';
part 'text_detector.dart';

// To indicate the format of image while creating input image from bytes
enum InputImageFormat {
  nv21,
  yv12,
  yuv_420_888,
  yuv420,
  bgra8888,
}

extension InputImageFormatMethods on InputImageFormat {
  // source: https://developers.google.com/android/reference/com/google/mlkit/vision/common/InputImage#constants
  static Map<InputImageFormat, int> get _values => {
        InputImageFormat.nv21: 17,
        InputImageFormat.yv12: 842094169,
        InputImageFormat.yuv_420_888: 35,
        InputImageFormat.yuv420: 875704438,
        InputImageFormat.bgra8888: 1111970369,
      };

  int get rawValue => _values[this] ?? 17;

  static InputImageFormat? fromRawValue(int rawValue) {
    return InputImageFormatMethods._values
        .map((k, v) => MapEntry(v, k))[rawValue];
  }
}

// To specify whether tflite models are stored in asset directory or file stored in device
enum CustomLocalModel { asset, file }

// The camera rotation angle to be specified
enum InputImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg
}

extension InputImageRotationMethods on InputImageRotation {
  static Map<InputImageRotation, int> get _values => {
        InputImageRotation.rotation0deg: 0,
        InputImageRotation.rotation90deg: 90,
        InputImageRotation.rotation180deg: 180,
        InputImageRotation.rotation270deg: 270,
      };

  int get rawValue => _values[this] ?? 0;

  static InputImageRotation? fromRawValue(int rawValue) {
    return InputImageRotationMethods._values
        .map((k, v) => MapEntry(v, k))[rawValue];
  }
}

/// Get instance of the individual api's using instance of [Vision]
/// For example
/// To get an instance of [ImageLabeler]
/// ImageLabeler imageLabeler = GoogleMlKit.instance.imageLabeler();

class Vision {
  Vision._();

  static const MethodChannel channel = MethodChannel('google_ml_kit');

  // Creates an instance of [GoogleMlKit] by calling the private constructor
  static final Vision instance = Vision._();

  /// Returns instance of [BarcodeScanner]. By default it searches the input image for all [BarcodeFormat]s.
  /// To limit the search model to specific [BarcodeFormat] pass list of [BarcodeFormat] as argument.
  BarcodeScanner barcodeScanner([List<BarcodeFormat>? formatList]) {
    return BarcodeScanner(formats: formatList);
  }

  /// Return an instance of [TextDetector].
  TextDetector textDetector() {
    return TextDetector._();
  }

  /// Returns an instance of Text Detector v2.
  TextDetectorV2 textDetectorV2() {
    return TextDetectorV2._();
  }
}

/// [InputImage] is the format Google' Ml kit takes to process the image
class InputImage {
  InputImage._(
      {this.filePath,
      this.bytes,
      required this.imageType,
      this.inputImageData});

  /// Create InputImage from path of image stored in device.
  factory InputImage.fromFilePath(String path) {
    return InputImage._(filePath: path, imageType: 'file');
  }

  /// Create InputImage by passing a file.
  factory InputImage.fromFile(File file) {
    return InputImage._(filePath: file.path, imageType: 'file');
  }

  /// Create InputImage using bytes.
  factory InputImage.fromBytes(
      {required Uint8List bytes, required InputImageData inputImageData}) {
    return InputImage._(
        bytes: bytes, imageType: 'bytes', inputImageData: inputImageData);
  }

  final String? filePath;
  final Uint8List? bytes;
  final String imageType;
  final InputImageData? inputImageData;

  Map<String, dynamic> _getImageData() {
    final map = <String, dynamic>{
      'bytes': bytes,
      'type': imageType,
      'path': filePath,
      'metadata':
          inputImageData == null ? 'none' : inputImageData!.getMetaData()
    };
    return map;
  }
}

/// Data of image required when creating image from bytes.
class InputImageData {
  /// Size of image.
  final Size size;

  /// Image rotation degree.
  final InputImageRotation imageRotation;

  /// Format of the input image.
  final InputImageFormat inputImageFormat;

  /// The plane attributes to create the image buffer on iOS.
  ///
  /// Not used on Android.
  final List<InputImagePlaneMetadata>? planeData;

  InputImageData(
      {required this.size,
      required this.imageRotation,
      required this.inputImageFormat,
      required this.planeData});

  /// Function to get the metadata of image processing purposes
  Map<String, dynamic> getMetaData() {
    final map = <String, dynamic>{
      'width': size.width,
      'height': size.height,
      'rotation': imageRotation.rawValue,
      'imageFormat': inputImageFormat.rawValue,
      'planeData': planeData
          ?.map((InputImagePlaneMetadata plane) => plane._serialize())
          .toList(),
    };
    return map;
  }
}

/// Plane attributes to create the image buffer on iOS.
///
/// When using iOS, [height], and [width] throw [AssertionError]
/// if `null`.
class InputImagePlaneMetadata {
  InputImagePlaneMetadata({
    required this.bytesPerRow,
    this.height,
    this.width,
  });

  /// The row stride for this color plane, in bytes.
  final int bytesPerRow;

  /// Height of the pixel buffer on iOS.
  final int? height;

  /// Width of the pixel buffer on iOS.
  final int? width;

  Map<String, dynamic> _serialize() => <String, dynamic>{
        'bytesPerRow': bytesPerRow,
        'height': height,
        'width': width,
      };
}
