import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class CaptureImage extends StatefulWidget {
  const CaptureImage({super.key});

  @override
  State<CaptureImage> createState() => _CaptureImageState();
}

class _CaptureImageState extends State<CaptureImage> {
  late Interpreter interpreter;
  late ImagePicker imagePicker;
  File? _image;
  String result = 'Results will be shown here';
  late ImageLabeler imageLabeler;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // loadModel();
    loadModel2();
    imagePicker = ImagePicker();
    // final ImageLabelerOptions options = ImageLabelerOptions(
    //   confidenceThreshold: 0.5,
    // );
    // imageLabeler = ImageLabeler(options: options);
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
      doImageLabeling();
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
        doImageLabeling();
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

  loadModel2() async {
    // final modelPath = await getModelPath('assets/ml/fruits_tm.tflite');
    final modelPath = await getModelPath('assets/ml/model_mobilenet.tflite');
    // final modelPath = await getModelPath('assets/ml/model_unquant.tflite');

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(width: 100),
                Container(
                  margin: const EdgeInsets.only(top: 100),
                  child: Stack(
                    children: <Widget>[
                      Stack(
                        children: <Widget>[
                          Center(
                            child: Image.asset(
                              'assets/frame.png',
                              height: 510,
                              width: 500,
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: _imgFromGallery,
                          onLongPress: _imgFromCamera,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            child: _image != null
                                ? Image.file(
                                    _image!,
                                    width: 335,
                                    height: 495,
                                    fit: BoxFit.fill,
                                  )
                                : Container(
                                    width: 340,
                                    height: 330,
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.black,
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
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}
