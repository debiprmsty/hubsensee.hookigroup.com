import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hubsensee_hooki/components/slider.dart';
import 'package:hubsensee_hooki/models/img_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart'; // Import the package
import 'package:image_cropper/image_cropper.dart'; // Import the package

class TestImage extends StatefulWidget {
  const TestImage({super.key});

  @override
  State<TestImage> createState() => _TestImageState();
}

// Bagian Atas
class _TestImageState extends State<TestImage> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;

  File? image;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    pickImage(ImageSource.camera);

    // Paksa orientasi lanskap untuk UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller.initialize();

    // Set orientasi kamera ke potrait
    await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
  }

  pickImage(ImageSource source) async {
    ImageAppModel(source: source).pick(onPick: (File? image) {
      // Set orientasi kamera kembali ke landscape setelah gambar selesai dipilih
      _controller.lockCaptureOrientation(DeviceOrientation.landscapeLeft);

      setState(() {
        this.image = image;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    // Reset preferensi orientasi
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SliderPage(),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      pickImage(ImageSource.camera);
                    },
                    child: Text("Camera"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      pickImage(ImageSource.gallery);
                    },
                    child: Text("Gallery"),
                  ),
                ],
              ),
              image != null
                  ? FaceCropper(image: image!) // Use the FaceCropper widget
                  : Text("No image selected"),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceCropper extends StatefulWidget {
  final File image;
  FaceCropper({required this.image});

  @override
  _FaceCropperState createState() => _FaceCropperState();
}

// Bagian Bawah
class _FaceCropperState extends State<FaceCropper> {
  File? croppedImage; // A file to store the cropped image
  Face? detectedFace; // To store information about the detected face

  @override
  void initState() {
    super.initState();
    cropImage();
  }

  void cropImage() async {
    final InputImage inputImage =
        InputImage.fromFile(widget.image); // Create an InputImage object
    final FaceDetector faceDetector =
        GoogleMlKit.vision.faceDetector(); // Create a FaceDetector object
    final List<Face> faces =
        await faceDetector.processImage(inputImage); // Get the list of faces

    if (faces.isNotEmpty) {
      // If there is at least one face
      final Face face = faces.first; // Get the first face
      final Rect faceRect = face.boundingBox; // Get the bounding box of the face

      setState(() {
        this.detectedFace = face;
      });

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      setState(() {
        this.croppedImage = File(croppedFile!.path); // Convert CroppedFile to File
      });
    } else {
      // If there is no face
      throw Exception('No face found in the image'); // Throw an exception
    }
  }

  @override
  Widget build(BuildContext context) {
    print(croppedImage);

    return Column(
    children: [
      Image.file(widget.image), // Display the original image
      Text("Original image"),
      if (detectedFace != null) 
        Column(
          children: [
            Text("Face detected!"),
            Text("Bounding Box: ${detectedFace!.smilingProbability}"),
            Text("Head rotation: ${detectedFace!.headEulerAngleY}"),
            // Add more information about the detected face as needed
          ],
        )
      else
        Text("No face detected"), // Display a message when no face is detected
      croppedImage != null
          ? Image.file(croppedImage!) // Display the cropped image
          : Text("No face cropped"),
      Text("Cropped image"),
    ],
  );
  }
}

