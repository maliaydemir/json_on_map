import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var mapController = MapController();

  var markers = <Marker>[];

  PlatformFile? selectedFile;

  String lonKey = 'Longitude';
  String latKey = 'Latitude';

  String exampleData = '''
  [{"Latitude":40.9954091,"Longitude":29.0658613},{"Latitude":41.005382,"Longitude":29.0276327},{"Latitude":41.0245601,"Longitude":29.0081856},{"Latitude":41.0273185,"Longitude":29.015615},{"Latitude":41.0234696,"Longitude":29.0423194},{"Latitude":41.0212723,"Longitude":29.0378687},{"Latitude":41.0198538,"Longitude":29.048569},{"Latitude":41.0411209,"Longitude":28.9797408},{"Latitude":41.0410573,"Longitude":28.9865084},{"Latitude":40.7886047,"Longitude":29.3820215}]
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Json on Map'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
            launchUrlString('https://github.com/maliaydemir/json_on_map',mode: LaunchMode.externalApplication);
          }, icon: const Icon(Icons.home_rounded))
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: LatLng(41.0182315, 29.1274329),
              zoom: 13,
              minZoom: 3,
              maxZoom: 18,
            ),
            layers: [
              TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c']),
              MarkerLayerOptions(
                markers: [
                  ...markers,
                ],
              )
            ],
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Card(
              child: Container(
                width: 200,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.grey.shade200,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Latitude Identifier'),
                              TextFormField(
                                initialValue: latKey,
                                onChanged: (val) {
                                  latKey = val;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        color: Colors.grey.shade200,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Longitude Identifier'),
                              TextFormField(
                                initialValue: lonKey,
                                onChanged: (val) {
                                  lonKey = val;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: showInfoDialog,
                        child: const ButtonBar(
                          children: [
                            Text(
                              'How It Works',
                            ),
                            Icon(Icons.info_outline_rounded),
                          ],
                        ),
                      ),
                      Card(
                        color: Colors.blue,
                        child: ListTile(
                          title: const Text(
                            'Import Json',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () async {
                            var fileRes = await FilePicker.platform
                                .pickFiles(allowMultiple: false);
                            if (fileRes != null) {
                              selectedFile = fileRes.files.first;
                              parseFile();
                            }
                          },
                        ),
                      ),
                      Card(
                        color: Colors.blue,
                        child: ListTile(
                          title: const Text(
                            'Paste from Clipboard',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () async {
                            parseClipboard();
                          },
                        ),
                      ),
                      selectedFile != null
                          ? Text(selectedFile!.name)
                          : Container(),
                      markers.isNotEmpty
                          ? Text('Processed Data: ' + markers.length.toString())
                          : Container(),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void parseFile() {
    if (selectedFile != null) {
      try {
        var bytes = selectedFile!.bytes;
        var txt = utf8.decode(bytes!.toList());
        Iterable itr = jsonDecode(txt);
        generateMarkers(itr);
      } catch (e) {
        Fluttertoast.showToast(
            msg: 'Parse error',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 3,
            textColor: Colors.white,
            fontSize: 16.0);
        // print(e);
      }
    }
  }

  Future<void> parseClipboard() async {
    var clipData = await Clipboard.getData('text/plain');
    if (clipData?.text != null) {
      try {
        Iterable itr = jsonDecode(clipData!.text!);
        generateMarkers(itr);
      } catch (e) {
        Fluttertoast.showToast(
            msg: 'Parse error',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 3,
            textColor: Colors.white,
            fontSize: 16.0);
        // print(e);
      }
    }
  }

  generateMarkers(Iterable itr) {
    try {
      markers.clear();
      markers = itr
          .map((e) => Marker(
              height: 12,
              width: 12,
              point: LatLng(e[latKey], e[lonKey]),
              builder: (context) {
                return const Icon(
                  Icons.circle_rounded,
                  size: 12,
                );
              }))
          .toList();
      if (markers.isNotEmpty) {
        mapController.move(markers.first.point, 10);
      }
      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Parse error',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          textColor: Colors.white,
          fontSize: 16.0);
      // print(e);
    }
  }

  void showInfoDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('How It Works?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text('Import json file or paste from clipboard data.'),
                const Text('Imported text must be fit in example data format.'),
                const Text('You have to set right paramaters for latitude and longitude keys.'),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/example1.png',
                      height: 250,
                      width: 250,
                    ),
                    Image.asset(
                      'assets/images/example2.png',
                      height: 250,
                      width: 250,
                    ),
                  ],
                ),
                TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: exampleData));
                      Fluttertoast.showToast(
                          msg: 'Coppied',
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.TOP,
                          timeInSecForIosWeb: 3,
                          textColor: Colors.white,
                          fontSize: 16.0);
                      Navigator.pop(context);
                    },
                    child: const Text('Copy Example Datas')),

              ],
            ),
          );
        });
  }
}
