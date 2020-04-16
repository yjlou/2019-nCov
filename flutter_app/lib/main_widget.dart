import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:location_collector/location_collector.dart';
import 'package:location_collector/location_collector_provider.dart';
import 'package:location_collector/location_repository.dart';
import 'package:location_collector/matched_result.dart';
import 'package:location_collector/sync_service.dart';

class MainWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _MainWidgetState();
  }
}

class _MainWidgetState extends State<MainWidget> {
  MatchedResultMetadata _matchedResultMetadata;
  Location _lastRecordedLocation;
  bool _isRunning;

  @override
  void initState() {
    super.initState();
    _getMatchedResultMetadata();
    _getLastRecordedLocation();
    _getLocationCollectorStatus();
    BackgroundLocatorLocationCollector()
        .registerOnReceiveLocation((Location location) {
      setState(() {
        _lastRecordedLocation = location;
      });
    });
  }

  void _getLocationCollectorStatus() {
    BackgroundLocatorLocationCollector().isRunning().then((isRunning) {
      setState(() {
        _isRunning = isRunning;
      });
    });
  }

  void _getMatchedResultMetadata() {
    SqliteRepository().getMatchedResultMetadata().then((metadata) {
      setState(() {
        _matchedResultMetadata =
            MatchedResultMetadata(metadata.count, metadata.time);
      });
    });
  }

  void _checkAgain() {
    setState(() {
      _matchedResultMetadata = null;
    });
    SyncService().tick().then((unused) {
      _getMatchedResultMetadata();
    });
  }

  void _getLastRecordedLocation() {
    // TODO: get updates automatically?
    SqliteRepository()
        .getLocation(beginIndex: -1)
        .then((List<Location> locationList) {
      setState(() {
        if (locationList == null || locationList.length == 0) {
          _lastRecordedLocation = null;
        } else {
          _lastRecordedLocation = locationList[0];
        }
      });
    });
  }

  Widget _makeStatusWidget(BuildContext context) {
    if (_matchedResultMetadata == null) {
      return CircleAvatar(
        child: Text('Loading...'),
        backgroundColor: Colors.black26,
        foregroundColor: Colors.black,
        radius: 100.0,
      );
    } else if (_matchedResultMetadata.count > 0) {
      return CircleAvatar(
        child: Text('We found ${_matchedResultMetadata.count} matches!'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        radius: 100.0,
      );
    } else {
      return CircleAvatar(
        child: Text(
          'No matches found!',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        radius: 100.0,
      );
    }
  }

  Widget _makeLastRecordedLocationWidget(BuildContext context) {
    String text;

    if (_lastRecordedLocation == null) {
      text = 'No location recorded...';
    } else {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
          _lastRecordedLocation.time.toInt());

      text =
          '${dateTime.toIso8601String()}: ${_lastRecordedLocation.latitude}, ${_lastRecordedLocation.longitude}';
    }

    return _CardWithLabel(Text('Last Recorded Location'), Text(text));
  }

  Widget _makeLastCheckTimeWidget(BuildContext context) {
    String body;
    if (_matchedResultMetadata == null) {
      body = 'Loading...';
    } else if (_matchedResultMetadata.time == null) {
      body = 'Never';
    } else {
      body = _matchedResultMetadata.time.toIso8601String();
    }

    return _CardWithLabel(Text('Last Checked'), Text(body));
  }

  void _toggleLocationCollectorStatus() {
    if (_isRunning) {
      BackgroundLocatorLocationCollector().stop().then((unused) {
        setState(() {
          _isRunning = false;
        });
      });
    } else {
      BackgroundLocatorLocationCollector().start().then((unused) {
        setState(() {
          _isRunning = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'title')),
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: _makeStatusWidget(context),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: <Widget>[
                  _makeLastCheckTimeWidget(context),
                  _makeLastRecordedLocationWidget(context),
                ],
                mainAxisAlignment: MainAxisAlignment.end,
              ),
            ),
          ],
        ),
        alignment: Alignment.center,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  icon: _isRunning == true
                      ? Icon(Icons.pause)
                      : Icon(Icons.play_arrow), // To show location histories
                  onPressed: _isRunning == null
                      ? null
                      : _toggleLocationCollectorStatus,
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _checkAgain,
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: null,
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceAround,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardWithLabel extends StatelessWidget {
  final Widget _title;
  final Widget _child;

  _CardWithLabel(this._title, this._child);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: <Widget>[
          Positioned(
              top: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: this._title,
              )),
          Align(
            child: Container(
              child: this._child,
              padding: EdgeInsets.fromLTRB(0, 25, 0, 10),
            ),
            alignment: Alignment.bottomCenter,
          )
        ],
      ),
    );
  }
}
