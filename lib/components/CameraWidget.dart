import 'dart:async';
import 'package:face_condition_detection/utils/label_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:face_condition_detection/service/detector.dart';
import 'package:camera/camera.dart';

class CameraWidget extends StatefulWidget {
  final String text;
  final int cameraIndex;

  CameraWidget({required this.text, required this.cameraIndex});

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String text = "";
  int _selectedCameraIndex = 0;
  int frameCount = 0;
  Detector? _detector;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initStateAsync();
  }

  void _initStateAsync() async {
    _initializeCamera(_selectedCameraIndex);
    Detector.start().then((instance) => {
          setState(() {
            _detector = instance;
            _subscription = instance.resultsStream.stream.listen((values) {
              setState(() {
                text = getEmojiFromLabel(values["prediction"]);
              });
            });
          })
        });
  }

  Future<void> _initializeCamera(int index) async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint("No cameras found");
        return;
      }

      if (_controller != null) {
        await _controller!.dispose();
      }

      // Find front and back cameras
      CameraDescription? backCamera;
      CameraDescription? frontCamera;

      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
        } else if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
        }
      }
      if (_selectedCameraIndex == 0 && frontCamera != null) {
        _controller = CameraController(frontCamera, ResolutionPreset.medium);
        _selectedCameraIndex = 1;
      } else if (backCamera != null) {
        _controller = CameraController(backCamera, ResolutionPreset.medium);
        _selectedCameraIndex = 0;
      }
      await _controller!.initialize().then((_) async {
        await _controller!.startImageStream(onLatestImageAvailable);
        setState(() {});
      });
      setState(() {});
    } on CameraException catch (e) {
      debugPrint("Camera initialization error: ${e.code} - ${e.description}");
    }
  }

  @override
  void didUpdateWidget(CameraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraIndex != widget.cameraIndex) {
      _initializeCamera(widget.cameraIndex);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          if (_controller != null && _controller!.value.isInitialized)
            cameraWidget(context)
          else
            Center(child: Text("Loading Camera...")),

          // Central Square Overlay
          Positioned(
            top: MediaQuery.of(context).size.height / 2 -
                150, // Center vertically
            left: MediaQuery.of(context).size.width / 2 -
                150, // Center horizontally
            child: Container(
              width: 300, // Updated to 300
              height: 300, // Updated to 300
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                color: Colors.transparent,
              ),
            ),
          ),
          // Circular Widget Overlay for Prediction
          Positioned(
            bottom: 50.0,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Color.fromARGB(66, 0, 0, 0)),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(color: Colors.white, fontSize: 70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Callback to receive each fram [CameraImage] perform inference on it
  void onLatestImageAvailable(CameraImage cameraImage) async {
    frameCount++;
    if (frameCount % 10 == 0) {
      frameCount = 0;
      _detector?.processFrame(cameraImage);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        _controller?.stopImageStream();
        _detector?.stop();
        _subscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        _initStateAsync();
        break;
      default:
    }
  }

  Widget cameraWidget(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }
    var camera = _controller!.value;
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * camera.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(_controller!)),
    );
  }
}
