import 'dart:io';

import 'package:flutter/material.dart';
import 'package:object_detection_app_tensorflowlite/MySplashPage.dart';
import "package:camera/camera.dart";
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:object_detection_app_tensorflowlite/BasicExampleAI.dart';
import 'package:object_detection_app_tensorflowlite/CameraExampleHome.dart';
import 'package:object_detection_app_tensorflowlite/HomePage.dart';
import 'package:object_detection_app_tensorflowlite/FuelEfficiencyPredictor.dart';
import 'package:object_detection_app_tensorflowlite/HousePricePrediction.dart';
import 'package:object_detection_app_tensorflowlite/CaptureImage.dart';
import 'package:object_detection_app_tensorflowlite/CaptureImageObjectDetect.dart';
import 'package:object_detection_app_tensorflowlite/RealTimeDetect.dart';

// import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Detection',
      // home: CameraExampleHome(),
      // home: CameraExampleHome(cameras: cameras),
      // home: RealTimeDetect(cameras: cameras),
      // home: MySplashPage(),
      // home: FuelEfficiencyPredictor(),
      // home: HousePricePrediction(),
      // home: CaptureImage(),
      home: CaptureImageObjectDetect(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  // State<CameraScreen> createState() => _CameraScreenState();
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  int selectedCameraIndex = 0;
  bool isInitialized = false;
  bool permissionGranted = false;

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    // Request camera permission using permission_handler package
    // You can implement this function to request permissions and set permissionGranted accordingly
    final status = await Permission.camera.request();
    if (status.isGranted) {
      permissionGranted = true;
      initializeCamera(selectedCameraIndex);
    } else {
      // Handle permission denied case
      setState(() {
        permissionGranted = false;
      });
    }
  }

  void initializeCamera(int index) async {
    controller = CameraController(cameras[index], ResolutionPreset.high);

    try {
      await controller.initialize();
      setState(() {
        isInitialized = true;
        selectedCameraIndex = index;
      });
    } catch (e) {
      // Handle camera initialization error
      print('Error initializing camera: $e');
    }
  }

  Future<void> takePicture(BuildContext context) async {
    if (!controller.value.isInitialized) {
      print('Error: Camera is not initialized.');
      return;
    }

    final directory = Directory('/storage/emulated/0/DCIM/Camera');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = join(directory.path, 'IMG_$timestamp.jpg');
    await File(path).create(recursive: true);

    try {
      await controller.takePicture().then((file) {
        file.saveTo(path);
        print('Picture saved to $path');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisplayPictureScreen(imagePath: path),
          ),
        );
      });
    } catch (e) {
      // Handle errors during picture taking
      print('Error taking picture: $e');
    }
  }

  void switchCamera() async {
    final newIndex = (selectedCameraIndex + 1) % cameras.length;

    setState(() {
      isInitialized = false;
    });

    await controller.dispose();
    initializeCamera(newIndex);
  }

  @override
  void dispose() {
    if (controller.value.isInitialized) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!permissionGranted) {
      return Scaffold(
        body: Center(
          child: Text('Camera permission is required to use this feature.'),
        ),
      );
    }

    if (!isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Camera'),
        actions: [
          IconButton(onPressed: switchCamera, icon: Icon(Icons.switch_camera)),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox.expand(child: CameraPreview(controller)),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => takePicture(context),
                  icon: Icon(Icons.camera, size: 80, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Captured Image')),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}

// class RealTimeDetect extends StatefulWidget {
//   const RealTimeDetect({super.key});

//   @override
//   State<RealTimeDetect> createState() => _RealTimeDetectState();
// }

// class _RealTimeDetectState extends State<RealTimeDetect> {
//   dynamic controller;
//   bool isBusy = false;
//   dynamic objectDetector;
//   late Size size;

//   @override
//   void initState() {
//     super.initState();
//     initializeCamera();
//   }

//   //TODO code to initialize the camera feed
//   initializeCamera() async {
//     //TODO initialize detector
//     const mode = DetectionMode.stream;
//     // Options to configure the detector while using with base model.
//     final options = ObjectDetectorOptions(
//       mode: mode,
//       classifyObjects: true,
//       multipleObjects: true,
//     );
//     objectDetector = ObjectDetector(options: options);

//     //TODO initialize controller
//     controller = CameraController(cameras[0], ResolutionPreset.high);
//     await controller.initialize().then((_) {
//       if (!mounted) {
//         return;
//       }
//       controller.startImageStream(
//         (image) => {
//           if (!isBusy) {isBusy = true, img = image, doObjectDetectionOnFrame()},
//         },
//       );
//     });
//   }

//   //close all resources
//   @override
//   void dispose() {
//     controller?.dispose();
//     objectDetector.close();
//     super.dispose();
//   }

//   //TODO object detection on a frame
//   dynamic _scanResults;
//   CameraImage? img;
//   doObjectDetectionOnFrame() async {
//     var frameImg = _inputImageFromCameraImage(img!);
//     List<DetectedObject> objects = await objectDetector.processImage(frameImg);
//     print("len= ${objects.length}");
//     setState(() {
//       _scanResults = objects;
//       isBusy = false;
//     });
//   }

//   final _orientations = {
//     DeviceOrientation.portraitUp: 0,
//     DeviceOrientation.landscapeLeft: 90,
//     DeviceOrientation.portraitDown: 180,
//     DeviceOrientation.landscapeRight: 270,
//   };

//   InputImage? _inputImageFromCameraImage(CameraImage image) {
//     // get image rotation
//     // it is used in android to convert the InputImage from Dart to Java
//     // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
//     // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
//     final camera = cameras[0];
//     final sensorOrientation = camera.sensorOrientation;
//     InputImageRotation? rotation;
//     if (Platform.isIOS) {
//       rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
//     } else if (Platform.isAndroid) {
//       var rotationCompensation =
//           _orientations[controller!.value.deviceOrientation];
//       if (rotationCompensation == null) return null;
//       if (camera.lensDirection == CameraLensDirection.front) {
//         // front-facing
//         rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
//       } else {
//         // back-facing
//         rotationCompensation =
//             (sensorOrientation - rotationCompensation + 360) % 360;
//       }
//       rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
//     }
//     if (rotation == null) return null;

//     // get image format
//     final format = InputImageFormatValue.fromRawValue(image.format.raw);
//     // validate format depending on platform
//     // only supported formats:
//     // * nv21 for Android
//     // * bgra8888 for iOS
//     if (format == null ||
//         (Platform.isAndroid && format != InputImageFormat.nv21) ||
//         (Platform.isIOS && format != InputImageFormat.bgra8888))
//       return null;

//     // since format is constraint to nv21 or bgra8888, both only have one plane
//     if (image.planes.length != 1) return null;
//     final plane = image.planes.first;

//     // compose InputImage using bytes
//     return InputImage.fromBytes(
//       bytes: plane.bytes,
//       metadata: InputImageMetadata(
//         size: Size(image.width.toDouble(), image.height.toDouble()),
//         rotation: rotation, // used only in Android
//         format: format, // used only in iOS
//         bytesPerRow: plane.bytesPerRow, // used only in iOS
//       ),
//     );
//   }

//   //Show rectangles around detected objects
//   Widget buildResult() {
//     if (_scanResults == null ||
//         controller == null ||
//         !controller.value.isInitialized) {
//       return const Text('');
//     }

//     final Size imageSize = Size(
//       controller.value.previewSize!.height,
//       controller.value.previewSize!.width,
//     );
//     CustomPainter painter = ObjectDetectorPainter(imageSize, _scanResults);
//     return CustomPaint(painter: painter);
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<Widget> stackChildren = [];
//     size = MediaQuery.of(context).size;
//     if (controller != null) {
//       stackChildren.add(
//         Positioned(
//           top: 0.0,
//           left: 0.0,
//           width: size.width,
//           height: size.height,
//           child: Container(
//             child: (controller.value.isInitialized)
//                 ? AspectRatio(
//                     aspectRatio: controller.value.aspectRatio,
//                     child: CameraPreview(controller),
//                   )
//                 : Container(),
//           ),
//         ),
//       );

//       // stackChildren.add(
//       //   Positioned(
//       //       top: 0.0,
//       //       left: 0.0,
//       //       width: size.width,
//       //       height: size.height,
//       //       child: buildResult()),
//       // );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Object detector"),
//         backgroundColor: Colors.pinkAccent,
//       ),
//       backgroundColor: Colors.black,
//       body: Container(
//         margin: const EdgeInsets.only(top: 0),
//         color: Colors.black,
//         child: Stack(children: stackChildren),
//       ),
//     );
//   }
// }

// class ObjectDetectorPainter extends CustomPainter {
//   ObjectDetectorPainter(this.absoluteImageSize, this.objects);

//   final Size absoluteImageSize;
//   final List<DetectedObject> objects;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final double scaleX = size.width / absoluteImageSize.width;
//     final double scaleY = size.height / absoluteImageSize.height;

//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0
//       ..color = Colors.pinkAccent;

//     for (DetectedObject detectedObject in objects) {
//       canvas.drawRect(
//         Rect.fromLTRB(
//           detectedObject.boundingBox.left * scaleX,
//           detectedObject.boundingBox.top * scaleY,
//           detectedObject.boundingBox.right * scaleX,
//           detectedObject.boundingBox.bottom * scaleY,
//         ),
//         paint,
//       );

//       // var list = detectedObject.labels;
//       // for (Label label in list) {
//       //   print("${label.text}   ${label.confidence.toStringAsFixed(2)}");
//       //   TextSpan span = TextSpan(
//       //       text: label.text,
//       //       style: const TextStyle(fontSize: 25, color: Colors.blue));
//       //   TextPainter tp = TextPainter(
//       //       text: span,
//       //       textAlign: TextAlign.left,
//       //       textDirection: TextDirection.ltr);
//       //   tp.layout();
//       //   tp.paint(
//       //       canvas,
//       //       Offset(detectedObject.boundingBox.left * scaleX,
//       //           detectedObject.boundingBox.top * scaleY));
//       //   break;
//       // }
//     }
//   }

//   @override
//   bool shouldRepaint(ObjectDetectorPainter oldDelegate) {
//     return oldDelegate.absoluteImageSize != absoluteImageSize ||
//         oldDelegate.objects != objects;
//   }
// }
