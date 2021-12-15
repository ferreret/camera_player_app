import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../main.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  // ---------------------------------------------------------------------------
  // VARIABLES -----------------------------------------------------------------
  // ---------------------------------------------------------------------------
  CameraController? controller;
  bool _isCameraInitialized = false;

  // ---------------------------------------------------------------------------
  // EVENTS --------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    // Hide the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);

    onNewCameraSelected(cameras[0]);
    super.initState();
  }

  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: _isCameraInitialized
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: RotatedBox(
                quarterTurns: 3,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: controller!.buildPreview(),
                ),
              ),
            )
          : Container(),
    );
  }

  // ---------------------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  // ---------------------------------------------------------------------------
  // METHODS -------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error initializing camera: $e');
      }
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }
}
