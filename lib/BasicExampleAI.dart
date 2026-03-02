import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';

class BasicExampleAI extends StatefulWidget {
  const BasicExampleAI({super.key});

  @override
  State<BasicExampleAI> createState() => _BasicExampleAIState();
}

class _BasicExampleAIState extends State<BasicExampleAI> {
  late Interpreter interpreter;
  var result = "results to be shown here...";
  final Logger logger = Logger();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
  }

  loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/linear.tflite');
  }

  performAction() {
    int value = int.parse(textEditingController.text);
    // For ex: if input tensor shape [1,1] and type is float32
    var input = [value];

    // if output tensor shape [1,1] and type is float32
    var output = List.filled(1, 0).reshape([1, 1]);
    print("Input: $input");
    logger.d("Logger is working! input: $input");
    logger.d("Logger is working! input: $output");
    // inference
    interpreter.run(input, output);

    // print the output
    print("Output: $output");
    // print log output[0][0]
    print("Output Value: ${output[0][0]}");

    setState(() {
      result = output[0][0].toStringAsFixed(2);
    });
  }

  TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Test Basic Example AI app"),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Container(
          margin: EdgeInsets.only(left: 40, right: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextField(
                controller: textEditingController,
                decoration: InputDecoration(hintText: "Type Number"),
              ),
              ElevatedButton(
                onPressed: () {
                  performAction();
                },
                child: Text('Get'),
              ),
              Text(
                '$result',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
