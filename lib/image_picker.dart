import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hubsensee_hooki/components/slider.dart';
import 'package:hubsensee_hooki/models/img_model.dart';
import 'package:hubsensee_hooki/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart'; // Import the package
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_cropper/flutter_image_cropper.dart';
import 'package:image/image.dart' as img;
 // Import the package

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
  bool isLoading = false; 

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
      ResolutionPreset.veryHigh,
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
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: abuputih,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  color: abuputih,
                  width: width * 0.75,
                  height: height,
                  child: SliderPage()
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 0, right: 28, top:0, bottom:0),
                      child: Text("HUBSENSEE\nAPP",style: poppins.copyWith(fontSize: 23, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 0, right: 28, top: 0, bottom:0),
                      child: GestureDetector(
                        onTap: () async {
                          pickImage(ImageSource.camera);
                          setState(() {
                            image = null; // Reset state image saat tombol ditekan
                          });
                        },
                        child: Card(
                          color: hitampekat,
                          elevation: 8, shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ), 
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.only(top: 8),
                                width: 80,
                                height: 55,
                                child: Icon(Icons.camera, size: 45,color: Colors.white,),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text("Absen", style: poppins.copyWith(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white,),),
                              )
                            ],
                          ),
                        )
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     ElevatedButton(
            //       onPressed: () async {
            //         pickImage(ImageSource.camera);
            //       },
            //       child: Text("Camera"),
            //     ),
            //     ElevatedButton(
            //       onPressed: () {
            //         pickImage(ImageSource.gallery);
            //       },
            //       child: Text("Gallery"),
            //     ),
            //   ],
            // ),
            image != null
                ? FaceCropper(image: image!) // Use the FaceCropper widget
                : Text("No image selected"),
          ],
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
  Face? detectedFace;
  bool isLoading = false;
// To store information about the detected face

  @override
  void initState() {
    super.initState();
    cropImage();

  }

  // // Cara Utama
  void cropImage() async {

    final InputImage inputImage = InputImage.fromFile(widget.image);
    final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
    final List<Face> faces = await faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      final Face face = faces.first;
      final Rect faceRect = face.boundingBox;

      final bytes = await File(widget.image.path).readAsBytes();
      final img.Image image = img.decodeImage(bytes)!;

      final croppedImage = img.copyCrop(
        image,
        x: faceRect.left.toInt(),
        y: faceRect.top.toInt(),
        width: faceRect.width.toInt(),
        height: faceRect.height.toInt(),
      );

      final croppedImagePath = widget.image.path;
      File(croppedImagePath).writeAsBytesSync(img.encodeJpg(croppedImage));

      setState(() {
        this.croppedImage = File(croppedImagePath);
         // Set loading state to false when image is cropped
         // Set isLoading to false when image is cropped
      });

      _showCroppedImageDialog();
    } else {
      _showMissImageDialog();

      setState(() {
        detectedFace = null;
        isLoading = false; // Set isLoading to false when face is not detected
      });
    }
  }



  // Cara Baru
//   void initState() {
//   super.initState();
//   detectFace();
// }

// void detectFace() async {
//   final InputImage inputImage = InputImage.fromFile(widget.image);
//   final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
//   final List<Face> faces = await faceDetector.processImage(inputImage);

//   if (faces.isNotEmpty) {
//     final Face face = faces.first;
//     final Rect faceRect = face.boundingBox;

//     // Crop the image around the detected face
//     cropImage(faceRect);
//   } else {
//     _showMissImageDialog();
//   }
// }

// void cropImage(Rect faceRect) async {
//   // Get the image dimensions
//   final decodedImage = await decodeImageFromList(widget.image.readAsBytesSync());
//   final imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

//   // Calculate the scaling ratio
//   final scaleX = widget.image.lengthSync() / imageSize.width;
//   final scaleY = widget.image.lengthSync() / imageSize.height;

//   // Scale and crop the image based on the face bounding box
//   final croppedFile = await FlutterImageCropper.cropRect(
//     sourcePath: widget.image.path,
//     rect: Rect.fromLTRB(
//       faceRect.left.toDouble() * scaleX,
//       faceRect.top.toDouble() * scaleY,
//       faceRect.right.toDouble() * scaleX,
//       faceRect.bottom.toDouble() * scaleY,
//     ),
//   );

//   setState(() {
//     croppedImage = croppedFile != null ? File(croppedFile.path) : null;
//   });

//   _showCroppedImageDialog();
// }


  //Modal Cropped Image/Terdeteksi Wajah
  //Modal Cropped Image/Terdeteksi Wajah
void _showCroppedImageDialog() {
  setState(() {
    isLoading = true; // Set isLoading to true before showing the dialog
  });

  // Show CircularProgressIndicator while isLoading is true
  if (isLoading) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from being dismissed
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // Simulate a delay for demonstration purposes
  Future.delayed(Duration(milliseconds: 2000), () {
    Navigator.of(context).pop(); // Dismiss the CircularProgressIndicator dialog

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Foto Anda'),
              content: Image.file(
                croppedImage!,
                scale: 0.5,
                height: 250,
                width: 250,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    print(croppedImage);
                  },
                  child: Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      setState(() {
        isLoading = false; // Set isLoading to false after the dialog is closed
      });
    });
  });
}




  //Modal Tidak Terdeteksi Wajah
  void _showMissImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.amber,
          title: Text('Maaf foto anda kurang jelas !'),
          content: Text('Silahkan ulangi foto wajah anda,pastikan dengan pencahayaan dan jangan lupa membersihkan camera'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print(croppedImage);

    return Column(
    children: [
      // Image.file(widget.image), // Display the original image
      // Text("Original image"),
      // if (detectedFace != null) 
      //   Column(
      //     children: [
      //       Text("Face detected!"),
      //       Text("Bounding Box: ${detectedFace!.smilingProbability}"),
      //       Text("Head rotation: ${detectedFace!.headEulerAngleY}"),
      //       // Add more information about the detected face as needed
      //     ],
      //   )
      // else
      //   Text("No face detected"), // Display a message when no face is detected
      // croppedImage != null
      //     ? Image.file(croppedImage!) // Display the cropped image
      //     : Text("No face cropped"),
      // Text("Cropped image"),
    ],
  );
  }
}

