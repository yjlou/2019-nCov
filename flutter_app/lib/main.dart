import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:location_collector/location_collector_provider.dart';
import 'package:location_collector/location_repository.dart';
import 'package:location_collector/sync_service.dart';
import 'package:path_provider/path_provider.dart';

import 'matched_result_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracker',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(title: 'Location Tracker'),
        '/matched_result': (context) => MatchedResultWidget(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Location> _locations = [];

  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    updateIsRunning();
  }

  void updateIsRunning() {
    LocationCollectorProvider.getInstance().isRunning().then(
            (isRunning) {
              setState(() {
                this.isRunning = isRunning;
              });
        });
  }

  void _startWorker() {
    LocationCollectorProvider.getInstance().start().then(
        (bool success) {
          updateIsRunning();
        }
    );
    SyncService().start().then(
        (bool success) {
          print('SyncService started');
        }
    );
  }

  void _stopWorker() {
    LocationCollectorProvider.getInstance().stop().then(
        (bool success) {
          updateIsRunning();
        }
    );
    SyncService().stop().then(
        (bool success) {
          print('SyncService stopped');
        }
    );
  }

  void _updateLocations() async {
    List<Location> _newLocation = await SqliteRepository().getLocation(beginIndex: -5);
    setState(() {
      _locations = _newLocation;
    });
  }

  void _clearLocations() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Press "Confirm" to delete all recorded location'),
          actions: <Widget>[
            RaisedButton(
              child: Text('Confirm'),
              onPressed: () async {
                await SqliteRepository().clear();
                Navigator.of(context).pop();
              },
            ),
            RaisedButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
    });

  }

  Future<void> _exportDatabase() async {
    Directory extDir = await getExternalStorageDirectory();
    Directory destDir = new Directory('${extDir.path}/events.pandemic');
    await destDir.create(recursive: true);
    String extFilePath = '${destDir.path}/recorded_location.json';
    await SqliteRepository().export(extFilePath);
    await FlutterShare.shareFile(
      title: 'recorded_location.json',
      text: 'Recorded location in JSON',
      filePath: extFilePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> locationWidgets = [];

    for (Location location in _locations) {
      DateTime t = DateTime.fromMillisecondsSinceEpoch(location.time.floor());

      locationWidgets.add(
        Text(
          '${t.toLocal()}: ${location.latitude} ${location.longitude}'
        )
      );
    }

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ...locationWidgets,
            Text('IsRunning: ${isRunning}'),
            ButtonBar(
              children: <Widget>[
                RaisedButton(
                  child: Text('Start Service'),
                  onPressed: _startWorker,
                ),
                RaisedButton(
                  child: Text('Stop Service'),
                  onPressed: _stopWorker,
                ),
              ]),
            ButtonBar(
              children: <Widget>[
                RaisedButton(
                  child: Text('Show Locations'),
                  onPressed: _updateLocations,
                ),
                RaisedButton(
                  child: Text('Clear Locations'),
                  onPressed: _clearLocations,
                )
              ]),
            ButtonBar(
              children: <Widget>[
                RaisedButton(
                  child: Text('Export DB'),
                  onPressed: _exportDatabase,
                ),
                RaisedButton(
                  child: Text('Matched Results'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/matched_result');
                  },
                )
              ]),
          ],
        ),
      ),
//      floatingActionButton: FloatingActionButton(
//        onPressed: _startWorker,
//        tooltip: 'startWorker',
//        child: Icon(Icons.add),
//      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
