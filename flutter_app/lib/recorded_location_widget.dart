import 'dart:io';

import 'package:covid19/common_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:location_collector/location_repository.dart';
import 'package:path_provider/path_provider.dart';

class RecordedLocationWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RecordedLocationState();
  }
}

class RecordedLocationState extends State<RecordedLocationWidget> {
  List<Location> _locationList = [];

  @override
  void initState() {
    super.initState();

    SqliteRepository().getLocation(beginIndex: -5).then((locationList) {
      setState(() {
        _locationList = locationList;
      });
    });
  }

  Widget buildLocationCard(Location location) {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(location.time.toInt());
    return CardWithLabel(
      title: Text(dateTime.toIso8601String()),
      child: Text('${location.latitude}, ${location.longitude}'),
    );
  }

  Widget buildLocationList() {
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              if (_locationList != null && index < _locationList.length) {
                return buildLocationCard(_locationList[index]);
              }
              return null;
            },
          ),
        ),
      ],
    );
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
    return Column(
      children: <Widget>[
        Expanded(child: buildLocationList()),
        RaisedButton(
          child: Text('Export Recorded Locations'),
          onPressed: _exportDatabase,
        ),
      ],
    );
  }
}
