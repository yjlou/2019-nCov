import 'dart:io';

import 'package:covid19/common_widget.dart';
import 'package:covid19/notifiers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:location_collector/location_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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
    Directory extDir;

    if (Platform.isAndroid) {
      extDir = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      extDir = await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError('We only support "Android" and "iOS"');
    }
    Directory destDir = new Directory('${extDir.path}/events.pandemic');
    await destDir.create(recursive: true);
    String extFilePath = '${destDir.path}/recorded_location.json';
    await SqliteRepository().export(extFilePath);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Consumer<AppLocaleModel>(
          builder: (context, model, child) {
            return Localizations.override(
              context: context,
              locale: model.locale,
              child: AlertDialog(
                content: I18nText(
                  'recorded_location.database_exported_message',
                  translationParams: {'database_path': extFilePath},
                ),
                actions: <Widget>[
                  FlatButton(
                    child: I18nText('share'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  FlatButton(
                    child: I18nText('cancel'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
    if (ok) {
      await FlutterShare.shareFile(
        title: 'recorded_location.json',
        text:
            FlutterI18n.translate(context, 'recorded_location.share_file_text'),
        filePath: extFilePath,
      );
    }
  }

  void _clearDatabase() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            FlutterI18n.translate(context, 'recorded_location.clear_alert'),
          ),
          actions: <Widget>[
            RaisedButton(
              child: Text(
                FlutterI18n.translate(context, 'confirm'),
              ),
              onPressed: () async {
                await SqliteRepository().clear();
                Navigator.of(context).pop();
              },
            ),
            RaisedButton(
              child: Text(
                FlutterI18n.translate(context, 'decline'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: buildLocationList()),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.file_download),
                  onPressed: _exportDatabase,
                ),
                Text(
                  FlutterI18n.translate(context, 'recorded_location.export'),
                ),
              ],
            ),
            Column(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _clearDatabase,
                ),
                Text(
                  FlutterI18n.translate(context, 'recorded_location.clear'),
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10),
        ),
      ],
    );
  }
}
