import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:object_detection_app_tensorflowlite/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isWorking = false;
  String result = "";
  late CameraController cameraController;
  late CameraImage imgCamera;

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }

      setState(() {
        cameraController.startImageStream((imageFromStream) {
          if (!isWorking) {
            isWorking = true;
            imgCamera = imageFromStream;
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage("assets/jarvis.jpg")),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    height: 320,
                    width: 330,
                    child: Image.asset("assets/camera.jpg"),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      initCamera();
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 35),
                      height: 270,
                      width: 360,
                      child: imgCamera == null
                          ? Container(
                              height: 270,
                              width: 340,
                              child: Icon(
                                Icons.photo_camera_front,
                                color: Colors.blueAccent,
                                size: 40,
                              ),
                            )
                          : AspectRatio(
                              aspectRatio: cameraController.value.aspectRatio,
                              child: CameraPreview(cameraController),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
