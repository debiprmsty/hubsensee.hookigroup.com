import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImageAppModel {
  
  ImageSource source;

  ImageAppModel({required this.source});

  pick({onPick}) async{
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if(image != null) {
      onPick(File(image.path));
    } else {
      onPick(null);
    }

  }
}