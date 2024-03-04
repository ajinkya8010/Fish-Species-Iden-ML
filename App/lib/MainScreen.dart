import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:tflite/tflite.dart';

import 'chat_page.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class FishData {
  final int id;
  final String commonName;
  final String scientificName;
  final String edible;

  FishData({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.edible,
  });
}

class _MainScreenState extends State<MainScreen> {
  bool _loading = true;
  late File _image;
  final imagePicker = ImagePicker();
  List predictions = [];
  String selectedState = 'Maharashtra'; // Default state
  Map<String, dynamic>? fishPrices;
  List<FishData> fishDataList = []; // List to store fish data
  FishData? selectedFishData; // Store detailed information about the selected fish
  String responseText = '';
  bool loading_ = false;

  getFromGallery() async {
    responseText = '';
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
    responseText = '';
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


    await getFishData(predictions[0]['label'].toString().substring(3));


    print(predictions);
  }

  Future<void> getFishPrice(String state, String species) async {

    try {
      setState(() {
        loading_ = true;
        responseText = ''; // Reset responseText when fetching new data
      });
      final response = await http.get(
        Uri.parse('http://192.168.186.194:5000/get_fish_prices?state=$state&fish_name=$species'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          responseText = 'Small: ${jsonData['small_price']}\n'
              'Medium: ${jsonData['medium_price']}\n'
              'Large: ${jsonData['large_price']}';
        });
      } else {
        // Show a message when data is not found
        setState(() {
          responseText = 'Sorry, data for this species is not available currently.';
        });
      }
    } catch (error) {
      // Handle specific errors
      if (error is SocketException) {
        setState(() {
          responseText = 'Error: Network issues. Please check your connection.';
        });
      } else {
        setState(() {
          responseText = 'Error: $error';
        });
      }
    } finally {
      // Set loading to false when fetching is completed
      setState(() {
        loading_ = false;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    loadModel();
    loadFishData(); // Call the function to load fish data when the screen is created
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Future<void> loadFishData() async {
    String csvData = await rootBundle.loadString('assets/mycsv.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

    // Skip the header row
    rows.removeAt(0);

    // Create FishData objects from CSV rows and add to the fishDataList
    fishDataList = rows.map(
          (row) {
        return FishData(
          id: int.parse(row[0].toString()),
          commonName: row[1].toString(),
          scientificName: row[2].toString(),
          edible: row[3].toString(),
        );
      },
    ).toList();
  }

  Future<void> getFishData(String species) async {
    // Check if fishDataList is not empty
    if (fishDataList.isNotEmpty) {
      // Find fish data based on the predicted species
      FishData? fishData = fishDataList.firstWhere(
            (fish) => fish.commonName == species,
        orElse: () => null as FishData,
      );

      if (fishData != null) {
        // Display detailed information about the predicted fish species
        setState(() {
          selectedFishData = fishData;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'TechXpark',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            Image.asset(
              'assets/logo.png',
              height: 60, // Adjust the height as needed
              width: 60, // Adjust the width as needed
            ),
          ],
        ),
        backgroundColor: Color(0xFF0C5894),
        toolbarHeight: 65,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 20,),
            Text(
              'TEST YOUR FISH',
              style: TextStyle(
                  color: Color(0xFF0C5894),
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
                      predictions[0]['label'].toString().substring(3),
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.black

                  ),
                ),
                /*Text(
                        'Accuracy: ' +
                            (predictions[0]['confidence'] * 100)
                                .toString()
                                .substring(0, 5) +
                            '%',
                        style: TextStyle(color: Colors.black),
                      ),*/
                DropdownButton<String>(
                  value: selectedState,
                  items: [
                    DropdownMenuItem<String>(
                      value: '', // empty value for hint
                      child: Text('Select State'),
                    ),
                    for (String value in ['Andhra Pradesh',
                      'Arunachal Pradesh',
                      'Assam',
                      'Bihar',
                      'Chhattisgarh',
                      'Goa',
                      'Gujarat',
                      'Haryana',
                      'Himachal Pradesh',
                      'Jammu and Kashmir',
                      'Jharkhand',
                      'Karnataka',
                      'Kerala',
                      'Madhya Pradesh',
                      'Maharashtra',
                      'Manipur',
                      'Meghalaya',
                      'Mizoram',
                      'Nagaland',
                      'Odisha',
                      'Punjab',
                      'Rajasthan',
                      'Sikkim',
                      'Tamil Nadu',
                      'Telangana',
                      'Tripura',
                      'Uttarakhand',
                      'Uttar Pradesh',
                      'West Bengal',
                      'Andaman and Nicobar Islands',
                      'Chandigarh',
                      'Dadra and Nagar Haveli',
                      'Daman and Diu',
                      'Delhi',
                      'Lakshadweep',
                      'Puducherry'])
                      DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                  ],
                  onChanged: (String? state) {
                    setState(() {
                      selectedState = state!;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: ()  async{
                    // Call the function to get fish price
                    await getFishPrice(selectedState, predictions[0]['label'].toString().substring(3));
                    print('Response Text: $responseText');

                  },
                  child: Text('Check Price'),
                ),
                SizedBox(height: 20),
                 loading_ ? CircularProgressIndicator() : Container(),
                // Display the selected state
                Text(responseText),
                // Display additional information about the selected fish species
                if (selectedFishData != null) ...[
                  Text('COMMON NAME: ${selectedFishData?.commonName}'),
                  Text('SCIENTIFIC NAME: ${selectedFishData?.scientificName}'),
                  Text('EDIBLE/NON-EDIBLE: ${selectedFishData?.edible}'),
                ],
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
                    style: ElevatedButton.styleFrom(
                      shape: StadiumBorder(),
                      primary: Color(0xFF0C5894),
                    ),
                    child: Center(
                      child: Text(
                        'CAPTURE WITH CAMERA',
                        style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                        ),
                        textAlign: TextAlign.center,

                      ),
                    ),
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
                    style: ElevatedButton.styleFrom(
                      shape: StadiumBorder(),
                      primary: Color(0xFF0C5894),
                    ),
                    child: Center(
                      child: Text(
                        'CHOOSE FROM GALLERY',
                        style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),


                SizedBox(
                  width: 10,
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatPage()),
                      );
                    },
                    child: Text('CHATBOT',
                        style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                        )),
                    style: ElevatedButton.styleFrom(
                        shape: StadiumBorder(), primary: Color(0xFF0C5894)),
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
