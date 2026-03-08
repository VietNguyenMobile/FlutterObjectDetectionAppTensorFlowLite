import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class CaptureImageObjectDetect extends StatefulWidget {
  const CaptureImageObjectDetect({super.key});

  @override
  State<CaptureImageObjectDetect> createState() =>
      _CaptureImageObjectDetectState();
}

class _CaptureImageObjectDetectState extends State<CaptureImageObjectDetect> {
  late Interpreter interpreter;
  late ImagePicker imagePicker;
  final Logger logger = Logger();
  File? _image;
  String result = 'Results will be shown here';
  late ImageLabeler imageLabeler;
  var image;

  late ObjectDetector objectDetector;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // loadModel();
    // loadModelLocal();

    // loadObjectDetectionModel();
    loadModelLocalObjectDetect();
    imagePicker = ImagePicker();
    // final ImageLabelerOptions options = ImageLabelerOptions(
    //   confidenceThreshold: 0.5,
    // );
    // imageLabeler = ImageLabeler(options: options);
  }

  loadObjectDetectionModel() async {
    const mode = DetectionMode.single;
    // Options to configure the detector while using with base model.
    final options = ObjectDetectorOptions(
      mode: mode,
      classifyObjects: true,
      multipleObjects: true,
    );
    objectDetector = ObjectDetector(options: options);
  }

  loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/house_prediction.tflite');
  }

  //TODO capture image using camera
  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    _image = File(pickedFile!.path);
    setState(() {
      _image;
      // doImageLabeling();
      doObjectDetection();
    });
  }

  //TODO choose image using gallery
  _imgFromGallery() async {
    XFile? pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        // doImageLabeling();
        doObjectDetection();
      });
    }
  }

  //TODO image labeling code here
  doImageLabeling() async {
    InputImage inputImage = InputImage.fromFile(_image!);
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    result = "";
    for (ImageLabel label in labels) {
      final String text = label.label;
      final int index = label.index;
      final double confidence = label.confidence;
      result += text + "  " + confidence.toStringAsFixed(2) + "\n";
    }
    setState(() {
      result;
    });
  }

  List<DetectedObject> objects = [];
  doObjectDetection() async {
    logger.d("Logger is working! doObjectDetection()");
    InputImage inputImage = InputImage.fromFile(_image!);

    objects = await objectDetector.processImage(inputImage);
    result = "";
    for (DetectedObject detectedObject in objects) {
      final Rect boundingBox = detectedObject.boundingBox;
      final int trackingId =
          detectedObject.trackingId ?? 0; // Tracking ID may be null
      final List<Label> labels = detectedObject.labels;

      // Process the detected object as needed
      // print('Detected object with tracking ID: $trackingId');
      // logger.d("Logger is working! trackingId : $trackingId");
      // print('Bounding box: $boundingBox');
      // logger.d("Logger is working! boundingBox : $boundingBox");
      for (Label label in labels) {
        logger.d("Logger is working! label : $label");
        print('Label: ${label.text}, Confidence: ${label.confidence}');
        result += "${label.text}  ${label.confidence.toStringAsFixed(2)}\n";
      }
    }
    setState(() {
      _image;
      result;
    });

    drawRectanglesAroundObjects();
  }

  loadModelLocal() async {
    // final modelPath = await getModelPath('assets/ml/fruits_tm.tflite');
    final modelPath = await getModelPath('assets/ml/model_mobilenet.tflite');
    // final modelPath = await getModelPath('assets/ml/model_unquant.tflite');

    final options = LocalLabelerOptions(
      confidenceThreshold: 0.5,
      modelPath: modelPath,
    );
    imageLabeler = ImageLabeler(options: options);
  }

  loadModelLocalObjectDetect() async {
    final modelPath = await getModelPath('assets/ml/fruits_tm.tflite');
    // final modelPath = await getModelPath('assets/ml/model_mobilenet.tflite');
    // final modelPath = await getModelPath('assets/ml/model_unquant.tflite');

    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.single,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );
    objectDetector = ObjectDetector(options: options);
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

  // @override
  // void dispose() {
  //   imageLabeler.close();
  //   //  controller?.dispose();
  //   objectDetector.close();
  //   super.dispose();
  // }

  drawRectanglesAroundObjects() async {
    image = await _image?.readAsBytes();
    image = await decodeImageFromList(image);
    logger.d(
      "Logger is working! drawRectanglesAroundObjects() ${objects.length}",
    );
    setState(() {
      image;
      objects;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            // fit: BoxFit.cover,
          ),
        ),

        child: Column(
          children: [
            const SizedBox(width: 100),
            Container(
              margin: const EdgeInsets.only(top: 100),
              child: Stack(
                children: <Widget>[
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _imgFromGallery,
                      onLongPress: _imgFromCamera,
                      child: Container(
                        width: 350,
                        height: 350,
                        margin: const EdgeInsets.only(top: 45),
                        child: image != null
                            ? Center(
                                child: FittedBox(
                                  child: SizedBox(
                                    width: image.width.toDouble(),
                                    height: image.height.toDouble(),
                                    child: CustomPaint(
                                      painter: ObjectPainter(
                                        objectList: objects,
                                        imageFile: image,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 350,
                                height: 350,
                                color: Colors.pinkAccent,
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 100,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Text(
                result,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  final List<DetectedObject> objectList;
  dynamic imageFile;
  ObjectPainter({required this.objectList, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 4;

    for (DetectedObject rectangle in objectList) {
      canvas.drawRect(rectangle.boundingBox, p);
      var list = rectangle.labels;
      for (Label label in list) {
        print("====> ${label.text} ${label.confidence.toStringAsFixed(2)}");
        TextSpan span = TextSpan(
          text: label.text,
          style: const TextStyle(fontSize: 100, color: Colors.blue),
        );
        TextPainter tp = TextPainter(
          text: span,

          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
          canvas,
          Offset(rectangle.boundingBox.left, rectangle.boundingBox.top),
        );
        break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
