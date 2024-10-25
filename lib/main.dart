import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
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
  bool _isComparing = false;

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

  void compareImages() async {
    if (_image1 != null && _image2 != null) {
      setState(() {
        _isComparing = true; // Show loading indicator during comparison
      });

      double percentage = await Future.delayed(
        const Duration(seconds: 1), // Simulate a slight delay for UI smoothness
        () => calculateImageMatchPercentage(_image1!, _image2!),
      );

      setState(() {
        _matchPercentage = percentage;
        _isComparing = false; // Hide loading indicator
      });
    }
  }

  double calculateImageMatchPercentage(File file1, File file2) {
    final img.Image? image1 = img.decodeImage(file1.readAsBytesSync());
    final img.Image? image2 = img.decodeImage(file2.readAsBytesSync());

    if (image1 == null || image2 == null) {
      throw Exception('Error decoding one or both images');
    }

    final width = image1.width < image2.width ? image1.width : image2.width;
    final height =
        image1.height < image2.height ? image1.height : image2.height;

    final img.Image resizedImage1 =
        img.copyResize(image1, width: width, height: height);
    final img.Image resizedImage2 =
        img.copyResize(image2, width: width, height: height);

    List<int> pixels1 = resizedImage1.getBytes();
    List<int> pixels2 = resizedImage2.getBytes();

    int totalPixels = width * height;
    int matchingPixels = 0;

    for (int i = 0; i < pixels1.length; i += 4) {
      int r1 = pixels1[i];
      int g1 = pixels1[i + 1];
      int b1 = pixels1[i + 2];
      int a1 = pixels1[i + 3];

      int r2 = pixels2[i];
      int g2 = pixels2[i + 1];
      int b2 = pixels2[i + 2];
      int a2 = pixels2[i + 3];

      if (r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2) {
        matchingPixels++;
      }
    }

    double matchPercentage = (matchingPixels / totalPixels) * 100;
    return matchPercentage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 219, 216, 216),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 219, 216, 216),
        title: Text(
          'Image Compare App',
          style: GoogleFonts.orbitron(
            color: Colors.black54,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            buildImagePicker(1),
            buildImagePicker(2),
            const SizedBox(height: 20),
            if (_isComparing)
              const CircularProgressIndicator(), // Show spinner during comparison
            if (_matchPercentage != null && !_isComparing)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Match Percentage:',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_matchPercentage!.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: _matchPercentage! > 70
                            ? Colors.green
                            : Colors.red, // Color based on similarity
                      ),
                    ),
                  ],
                ),
              ),
            if (_image1 != null && _image2 != null && !_isComparing)
              ElevatedButton(
                onPressed: compareImages,
                child: const Text('Compare Images'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Function to build image picker
  Widget buildImagePicker(int imageNumber) {
    return Expanded(
      child: GestureDetector(
        onTap: () => pickImage(imageNumber),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              height: 200,
              child: Center(
                child: _getImage(imageNumber),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Function to show image or placeholder
  Widget _getImage(int imageNumber) {
    File? imageFile = imageNumber == 1 ? _image1 : _image2;
    if (imageFile != null) {
      return Image.file(imageFile, fit: BoxFit.cover, width: double.infinity);
    } else {
      return const Icon(Icons.image, size: 100, color: Colors.grey);
    }
  }
}
