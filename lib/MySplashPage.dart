import "package:flutter/material.dart";
import "package:object_detection_app_tensorflowlite/HomePage.dart";
import "package:splashscreen/splashscreen.dart";

class MySplashPage extends StatefulWidget {
  const MySplashPage({super.key});

  @override
  State<MySplashPage> createState() => _MySplashPageState();
}

class _MySplashPageState extends State<MySplashPage> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      title: Text(
        "Object Detection App",
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      seconds: 12,
      imageBackground: Image.asset("assets/back.jpg").image,
      loaderColor: Colors.pink,
      backgroundColor: Colors.pink,
      navigateAfterSeconds: HomePage(),
      styleTextUnderTheLoader: TextStyle(),
      loadingTextPadding: EdgeInsets.all(20),
      useLoader: true,
      loadingText: Text("Loading...", style: TextStyle(color: Colors.white)),
    );
  }
}
