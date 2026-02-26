import 'dart:io';

import 'package:flutter/material.dart';
import 'package:object_detection_app_tensorflowlite/MySplashPage.dart';
import "package:camera/camera.dart";
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return MaterialApp(title: 'Object Detection', home: CameraScreen());
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
