import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:object_detection_app_tensorflowlite/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';

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

  late Interpreter _interpreter;
  static List<String> _labels = [];
  final Logger logger = Logger();

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenet_v1_1.0_224.tflite',
      );

      String labelsData = await rootBundle.loadString(
        'assets/mobilenet_v1_1.0_224.txt',
      );
      _labels = labelsData.split('\n').map((label) => label.trim()).toList();

      print('Model loaded successfully');
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  List<dynamic> runInference(var input) {
    // Determine the shape and type of the output based on your specific model
    var output = List.filled(
      1 * 2,
      0,
    ).reshape([1, 2]); // Example for an output shape of [1, 2]
    _interpreter.run(input, output);
    return output;
  }

  void close() {
    _interpreter.close();
  }

  bool permissionGranted = false;

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
    loadModel();
  }

  @override
  void dispose() async {
    cameraController.dispose();
    close();
    super.dispose();
  }

  Future<void> requestCameraPermission() async {
    // Request camera permission using permission_handler package
    // You can implement this function to request permissions and set permissionGranted accordingly
    final status = await Permission.camera.request();
    if (status.isGranted) {
      permissionGranted = true;
      initCamera();
    } else {
      // Handle permission denied case
      setState(() {
        permissionGranted = false;
      });
    }
  }

  initCamera() {
    print("Camera initialized");
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }

      print("isWorking: $isWorking");
      logger.d("Logger is working! Result: $isWorking");
      setState(() {
        cameraController.startImageStream((imageFromStream) {
          // how to show debug log isWorking
          if (!isWorking) {
            isWorking = true;
            imgCamera = imageFromStream;
            runModelOnStreamFrames();
          }
        });
      });
    });
  }

  runModelOnStreamFrames() async {
    try {
      var input = preprocessImage(imgCamera);
      var output = runInference(input);
      var topResult = _processOutput(output);
      logger.d("Logger is working! Result: $topResult");

      setState(() {
        result = topResult;
        isWorking = false;
      });
    } catch (e) {
      print("Error running inference: $e");
      setState(() {
        isWorking = false;
      });
    }
  }

  String _processOutput(List<dynamic> output) {
    if (output.isEmpty || output[0] == null) {
      return "No results";
    }

    final scores = output[0] as List<dynamic>;
    if (scores.isEmpty) {
      return "No scores";
    }

    int topIndex = 0;
    double topScore = (scores[0] as num).toDouble();

    for (int i = 1; i < scores.length && i < _labels.length; i++) {
      double score = (scores[i] as num).toDouble();
      if (score > topScore) {
        topScore = score;
        topIndex = i;
      }
    }

    String label = topIndex < _labels.length ? _labels[topIndex] : "Unknown";
    String confidence = (topScore * 100).toStringAsFixed(2);

    return "$label: $confidence%";
  }

  List<List<List<List<double>>>> preprocessImage(CameraImage image) {
    const int targetSize = 224;

    final int srcWidth = image.width;
    final int srcHeight = image.height;

    final input = List.generate(
      1,
      (_) => List.generate(
        targetSize,
        (_) => List.generate(targetSize, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < targetSize; y++) {
      final int srcY = (y * srcHeight / targetSize).floor();

      for (int x = 0; x < targetSize; x++) {
        final int srcX = (x * srcWidth / targetSize).floor();

        final rgb = _readRgbPixel(image, srcX, srcY);

        input[0][y][x][0] = (rgb[0] - 127.5) / 127.5;
        input[0][y][x][1] = (rgb[1] - 127.5) / 127.5;
        input[0][y][x][2] = (rgb[2] - 127.5) / 127.5;
      }
    }

    return input;
  }

  List<double> _readRgbPixel(CameraImage image, int x, int y) {
    if (image.format.group == ImageFormatGroup.bgra8888 &&
        image.planes.isNotEmpty) {
      final plane = image.planes.first;
      final int bytesPerPixel = plane.bytesPerPixel ?? 4;
      final int index = y * plane.bytesPerRow + x * bytesPerPixel;

      final int b = plane.bytes[index];
      final int g = plane.bytes[index + 1];
      final int r = plane.bytes[index + 2];

      return [r.toDouble(), g.toDouble(), b.toDouble()];
    }

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int yIndex = y * yPlane.bytesPerRow + x;
    final int uvX = x ~/ 2;
    final int uvY = y ~/ 2;

    final int uvIndex =
        uvY * uPlane.bytesPerRow + uvX * (uPlane.bytesPerPixel ?? 1);

    final int yp = yPlane.bytes[yIndex];
    final int up = uPlane.bytes[uvIndex];
    final int vp = vPlane.bytes[uvIndex];

    final double yf = yp.toDouble();
    final double uf = up.toDouble() - 128.0;
    final double vf = vp.toDouble() - 128.0;

    final double r = yf + 1.402 * vf;
    final double g = yf - 0.344136 * uf - 0.714136 * vf;
    final double b = yf + 1.772 * uf;

    return [_clampColor(r), _clampColor(g), _clampColor(b)];
  }

  double _clampColor(double value) {
    return math.max(0.0, math.min(255.0, value));
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
                Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 320,
                        width: 360,
                        color: Colors.black,
                        child: Image.asset("assets/camera.jpg"),
                      ),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // initCamera();
                        },
                        child: Container(
                          margin: EdgeInsets.only(top: 35),
                          height: 270,
                          width: 360,
                          child: isWorking
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
                                  aspectRatio:
                                      cameraController.value.aspectRatio,
                                  child: CameraPreview(cameraController),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
