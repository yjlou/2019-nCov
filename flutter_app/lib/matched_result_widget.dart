import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location_collector/location_repository.dart';
import 'package:location_collector/matched_result.dart';
import 'package:location_collector/sync_service.dart';

class _MatchedPointWidget extends StatelessWidget {
  final MatchedPoint _point;

  _MatchedPointWidget(this._point);

  @override
  Widget build(BuildContext context) {
    var b = DateTime.fromMillisecondsSinceEpoch(this._point.userBegin * 1000);
    var e = DateTime.fromMillisecondsSinceEpoch(this._point.userEnd * 1000);
    return GestureDetector(
      onTap: null, // TODO: Open Google Maps?
      child: Card(
        child: Column(
          children: <Widget>[
            Text('PatientDesc: ${this._point.patientDesc}'),
            Text('UserDesc: ${this._point.userDesc}'),
            Text('Begin: ${b.toIso8601String()}'),
            Text('End: ${e.toIso8601String()}'),
            Text('Where: ${this._point.userLat}, ${this._point.userLng}'),
          ],
        )
      )
    );
  }
}

class MatchedResultWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MatchedResultWidgetState();
  }
}

class _MatchedResultWidgetState extends State<MatchedResultWidget> {
  String _checkerStatus = '';
  List<MatchedPoint> _matchedPointList = [];

  @override
  initState() {
    super.initState();
    _loadMatchedResult();
  }

  void _loadMatchedResult() {
    SqliteRepository().loadMatchedResult().then(
      (list) {
        setState(() {
          this._matchedPointList = list;
        });
      });
  }

  void _checkNow() async {
    StreamController streamController = StreamController();
    streamController.stream.listen((data) {
      setState(() {
        _checkerStatus = data;
      });
      print('received data: ${data}');
    }, onDone: () {
      print('task done');
      _loadMatchedResult();
    }, onError: (error) {
      print('error: ${error}');
    });

    try {
      setState(() {
        _checkerStatus = 'start checking...';
      });
      await SyncService().tick(stream: streamController);
    } catch (error) {
      print(error);
    } finally {
      print('Check completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matched Results')),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPersistentHeader(
            delegate: _MatchedResultWidgetHeaderDelegate(_checkNow),
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                if (index == 0 && _matchedPointList.length == 0) {
                  return Text('No matched results, press "Check Now" to check.');
                }
                if (index >= _matchedPointList.length) {
                  return null;
                }
                return _MatchedPointWidget(_matchedPointList[index]);
              },
            ),
          ),
        ],
      ),

      bottomSheet: Text(_checkerStatus),
    );
  }
}


class _MatchedResultWidgetHeaderDelegate extends SliverPersistentHeaderDelegate {
  Function _checkNow;

  _MatchedResultWidgetHeaderDelegate(this._checkNow);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ButtonBar(
      children: [
        RaisedButton(
          child: Text('Check Now'),
          onPressed: _checkNow,
        ),
        RaisedButton(
          child: Text('Back'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  @override
  // TODO: implement maxExtent
  double get maxExtent => 60;

  @override
  // TODO: implement minExtent
  double get minExtent => 60;

  @override
  bool shouldRebuild(_MatchedResultWidgetHeaderDelegate oldDelegate) {
    // TODO: implement shouldRebuild
    return this._checkNow != oldDelegate._checkNow;
  }

}