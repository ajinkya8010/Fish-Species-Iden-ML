// ignore_for_file: sort_child_properties_last, prefer_const_constructors, prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _loading = true;
  late File _image;
  final imagePicker = ImagePicker();
  List predictions = [];

  getFromGallery() async {
    var image = await imagePicker.getImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    } else {
      _image = File(image.path);
    }

    detectImage(_image);
  }

  getFromCamera() async {
    var image = await imagePicker.getImage(source: ImageSource.camera);
    if (image == null) {
      return null;
    } else {
      _image = File(image.path);
    }
    detectImage(_image);
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: 'assets/labels.txt',
    );
  }

  detectImage(File img) async {
    var prediction = await Tflite.runModelOnImage(
        path: img.path,
        numResults: 2,
        threshold: 0.6,
        imageMean: 127.5,
        imageStd: 127.5);

    setState(() {
      _loading = false;
      predictions = prediction!;
    });
    print(predictions);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GROUP 5',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Color(0xFFF23F44),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 20,),
            Text(
              'Test your Fish',
              style: TextStyle(
                  color: Color(0xFFF23F44),
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 20,
            ),
            _loading == false
                ? Column(
                    children: [
                      Container(
                        height: 200,
                        width: 200,
                        child: Image.file(_image),
                      ),
                      Text(
                        'Prediction: Object in image is ' +
                            predictions[0]['label'].toString(),
                        style: TextStyle(color: Colors.black),
                      ),
                      /*Text(
                        'Accuracy: ' +
                            (predictions[0]['confidence'] * 100)
                                .toString()
                                .substring(0, 5) +
                            '%',
                        style: TextStyle(color: Colors.black),
                      ),*/
                    ],
                  )
                : Container(),
            Row(
              children: [
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      getFromCamera();
                    },
                    child: Text('Capture', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                        shape: StadiumBorder(), primary: Color(0xFFF23F44)),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      getFromGallery();
                    },
                    child: Text('Choose from Gallery',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                        shape: StadiumBorder(), primary: Color(0xFFF23F44)),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
