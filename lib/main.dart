import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

void main() {
  runApp(ImageCompareApp());
}

class ImageCompareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageCompareScreen(),
    );
  }
}

class ImageCompareScreen extends StatefulWidget {
  @override
  _ImageCompareScreenState createState() => _ImageCompareScreenState();
}

class _ImageCompareScreenState extends State<ImageCompareScreen> {
  File? _image1;
  File? _image2;
  double? _matchPercentage;

  final picker = ImagePicker();

  Future<void> pickImage(int imageNumber) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        if (imageNumber == 1) {
          _image1 = File(pickedFile.path);
        } else {
          _image2 = File(pickedFile.path);
        }
      }
    });
  }

  void compareImages() {
    if (_image1 != null && _image2 != null) {
      double percentage = calculateImageMatchPercentage(_image1!, _image2!);
      setState(() {
        _matchPercentage = percentage;
      });
    }
  }

  double calculateImageMatchPercentage(File file1, File file2) {
    // Decode the images
    final img.Image? image1 = img.decodeImage(file1.readAsBytesSync());
    final img.Image? image2 = img.decodeImage(file2.readAsBytesSync());

    if (image1 == null || image2 == null) {
      throw Exception('Error decoding one or both images');
    }

    // Resize both images to the same dimensions
    final width = image1.width < image2.width ? image1.width : image2.width;
    final height =
        image1.height < image2.height ? image1.height : image2.height;

    final img.Image resizedImage1 =
        img.copyResize(image1, width: width, height: height);
    final img.Image resizedImage2 =
        img.copyResize(image2, width: width, height: height);

    // Get the raw pixel data as lists of integers
    List<int> pixels1 = resizedImage1.getBytes();
    List<int> pixels2 = resizedImage2.getBytes();

    int totalPixels = width * height;
    int matchingPixels = 0;

    // Compare pixel data
    for (int i = 0; i < pixels1.length; i += 4) {
      // Check if both pixels match (RGBA format)
      int r1 = pixels1[i]; // Red component of pixel1
      int g1 = pixels1[i + 1]; // Green component of pixel1
      int b1 = pixels1[i + 2]; // Blue component of pixel1
      int a1 = pixels1[i + 3]; // Alpha component of pixel1

      int r2 = pixels2[i]; // Red component of pixel2
      int g2 = pixels2[i + 1]; // Green component of pixel2
      int b2 = pixels2[i + 2]; // Blue component of pixel2
      int a2 = pixels2[i + 3]; // Alpha component of pixel2

      // Compare RGBA values
      if (r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2) {
        matchingPixels++;
      }
    }

    // Calculate the match percentage
    double matchPercentage = (matchingPixels / totalPixels) * 100;
    return matchPercentage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Compare App')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () => pickImage(1),
                child: Text('Pick First Image'),
              ),
              ElevatedButton(
                onPressed: () => pickImage(2),
                child: Text('Pick Second Image'),
              ),
            ],
          ),
          if (_image1 != null && _image2 != null)
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Image.file(_image1!)),
                  Expanded(child: Image.file(_image2!)),
                ],
              ),
            ),
          if (_matchPercentage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Match Percentage: ${_matchPercentage!.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 18),
              ),
            ),
          if (_image1 != null && _image2 != null)
            ElevatedButton(
              onPressed: compareImages,
              child: Text('Compare Images'),
            ),
        ],
      ),
    );
  }
}
