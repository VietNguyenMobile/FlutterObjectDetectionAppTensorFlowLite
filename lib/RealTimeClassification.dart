import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class RealTimeClassification extends StatefulWidget {
  const RealTimeClassification({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<RealTimeClassification> createState() => _RealTimeClassificationState();
}

class _RealTimeClassificationState extends State<RealTimeClassification> {
  // Use `late` as we will initialize it in `initState`
  late CameraController controller;

  // `CameraImage` is often made nullable as images are processed in a stream
  // and might not be available immediately or always needed.
  CameraImage? img;
  bool isBusy = false;
  String result = "results to be shown here...";
  late ImageLabeler imageLabeler;
  int _cameraIndex = 0;
  final Logger logger = Logger();

  // A boolean flag to track when the camera is fully initialized and ready for display
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    // final ImageLabelerOptions options = ImageLabelerOptions(
    //   confidenceThreshold: 0.5,
    // );
    // imageLabeler = ImageLabeler(options: options);

    // local model
    loadModelLocal();
    _initializeCamera();
  }

  loadModelLocal() async {
    final modelPath = await getModelPath('assets/ml/fruits_tm.tflite');
    // final modelPath = await getModelPath('assets/ml/model_mobilenet.tflite');

    final options = LocalLabelerOptions(
      confidenceThreshold: 0.5,
      modelPath: modelPath,
    );
    imageLabeler = ImageLabeler(options: options);
  }

  Future<String> getModelPath(String asset) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
    }
    return file.path;
  }

  Future<void> _initializeCamera() async {
    // 1. Initialize the controller with a specific camera and resolution
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high, // Use a suitable resolution preset
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      // 2. Await the initialization
      await controller.initialize().then((_) {
        if (!mounted) return;
        controller.startImageStream((image) {
          if (!isBusy) {
            isBusy = true;
            img = image;
            doImageLabeling();
          }
          ;
          setState(() {});
        });
      });

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      // Handle camera initialization errors
      debugPrint("Error initializing camera: $e");
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = widget.cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888))
      return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  doImageLabeling() async {
    logger.d("Logger is working! doImageLabeling()");
    result = "";

    InputImage? inputImage = _inputImageFromCameraImage(img!);
    final List<ImageLabel> labels = await imageLabeler.processImage(
      inputImage!,
    );

    logger.d("Logger is working! doImageLabeling()");

    for (ImageLabel label in labels) {
      final String text = label.label;
      final int index = label.index;
      final double confidence = label.confidence;
      result += text + "  " + confidence.toStringAsFixed(2) + "\n";
    }
    logger.d("Logger is working! result: $result");
    setState(() {
      result;
      isBusy = false;
    });
  }

  @override
  void dispose() {
    // Dipose of the controller when the widget is removed from the tree
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the boolean flag to show a loading indicator or the camera preview
    if (_isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text("Camera Preview")),
        body: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            Container(
              margin: const EdgeInsets.only(left: 10, bottom: 60),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  result,
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
