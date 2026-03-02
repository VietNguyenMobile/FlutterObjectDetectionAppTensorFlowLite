import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class CameraExampleHome extends StatefulWidget {
  const CameraExampleHome({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<CameraExampleHome> createState() => _CameraExampleHomeState();
}

class _CameraExampleHomeState extends State<CameraExampleHome> {
  // Use `late` as we will initialize it in `initState`
  late CameraController controller;

  // `CameraImage` is often made nullable as images are processed in a stream
  // and might not be available immediately or always needed.
  CameraImage? img;
  bool isBusy = false;
  String result = "results to be shown here...";
  late ImageLabeler imageLabeler;
  int _cameraIndex = 0;

  // A boolean flag to track when the camera is fully initialized and ready for display
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    final ImageLabelerOptions options = ImageLabelerOptions(
      confidenceThreshold: 0.5,
    );
    imageLabeler = ImageLabeler(options: options);
    _initializeCamera();
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

    final _orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    try {
      // 2. Await the initialization
      await controller.initialize().then((_) {
        if (!mounted) return;
        controller.startImageStream((CameraImage img) {
          if (!isBusy) {
            isBusy = true;
            img = img;
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

  doImageLabeling() async {
    result = "";
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
