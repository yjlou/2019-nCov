import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';

import 'common_widget.dart';
import 'notifiers.dart';

class MainWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MainWidgetState();
  }
}

class _MainWidgetState extends State<MainWidget> {
  String _checkerMessage;
  bool _checkFailed = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _makeStatusWidget(BuildContext context) {
    return Consumer<RecordedLocationCheckerModel>(builder: (_, model, child) {
      final metadata = model.metadata;
      if (metadata == null) {
        return CircleAvatar(
          child: Text(FlutterI18n.translate(context, 'main.loading')),
          backgroundColor: Colors.black26,
          foregroundColor: Colors.black,
          radius: 100.0,
        );
      } else if (metadata.count > 0) {
        return CircleAvatar(
          child: Text(
            FlutterI18n.plural(context, 'main.match_found', metadata.count),
          ),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          radius: 100.0,
        );
      } else {
        return CircleAvatar(
          child: Text(
            FlutterI18n.plural(context, 'main.match_found', 0),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          radius: 100.0,
        );
      }
    });
  }

  Widget _makeLastRecordedLocationWidget(BuildContext context) {
    return GestureDetector(
      child: CardWithLabel(
        title: Text(FlutterI18n.translate(context, 'main.last_recorded_location'),),
        child: Selector<LocationCollectorModel, String>(
          selector: (_, model) {
            final location = model.lastRecordedLocation;
            if (location == null) {
              return FlutterI18n.translate(context, 'main.no_recorded_location');
            }
            DateTime dateTime =
                DateTime.fromMillisecondsSinceEpoch(location.time.toInt());
            return '${dateTime.toIso8601String()} ${location.latitude} ${location.longitude}';
          },
          builder: (context, text, child) => Text(text),
        ),
      ),
      onTap: () {
        Provider.of<AppPageModel>(context, listen: false)
            .goto(AppPageEnum.RECORDED_LOCATION);
      },
    );
  }

  Widget _makeLastCheckTimeWidget(BuildContext context) {
    return Consumer<RecordedLocationCheckerModel>(
      builder: (_, model, child) {
        String body = FlutterI18n.translate(context, 'main.loading');
        Color labelColor = Colors.black26;
        if (model.metadata != null) {
          if (model.lastCheckedTime == null) {
            body = FlutterI18n.translate(context, 'main.never');
          } else {
            body = model.lastCheckedTime.toIso8601String();
          }
          if (model.matchedCount > 0) {
            labelColor = Colors.red;
          } else {
            labelColor = Colors.greenAccent;
          }
        }
        return GestureDetector(
          child: CardWithLabel(
            title: Text(FlutterI18n.translate(context, 'main.last_checked')),
            child: Text(body),
            labelColor: labelColor,
          ),
          onTap: () {
            Provider.of<AppPageModel>(context, listen: false)
                .goto(AppPageEnum.MATCHED_RESULT);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.lerp(
              Alignment.topCenter,
              Alignment.center,
              0.4,
            ),
            child: _makeStatusWidget(context),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              children: <Widget>[
                makeOptionalCheckerStatusWidget(),
                _makeLastCheckTimeWidget(context),
                _makeLastRecordedLocationWidget(context),
              ],
              mainAxisAlignment: MainAxisAlignment.end,
            ),
          ),
        ],
      ),
      alignment: Alignment.center,
    );
  }
}
