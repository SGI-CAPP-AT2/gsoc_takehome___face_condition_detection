import 'package:face_condition_detection/components/CameraWidget.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String circleText = '😑';
  int cameraIndex = 0;

  void updateCircleText(String newText) {
    setState(() {
      circleText = newText;
    });
  }

  void changeCamera() {
    debugPrint('Changing camera $cameraIndex');
    setState(() {
      cameraIndex = (cameraIndex + 1) % 2; // Toggle between 0 and 1
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraWidget(
            text: circleText,
            cameraIndex: cameraIndex,
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.switch_camera, color: Colors.white, size: 30),
              onPressed: changeCamera,
            ),
          ),
        ],
      ),
    );
  }
}
