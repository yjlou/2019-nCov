import 'package:covid19/common_widget.dart';
import 'package:covid19/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';
import 'package:location_collector/matched_result.dart';
import 'package:provider/provider.dart';

class _MatchedPointWidget extends StatelessWidget {
  final MatchedPoint point;
  final int index;

  _MatchedPointWidget({this.point, this.index});

  @override
  Widget build(BuildContext context) {
    var b = DateTime.fromMillisecondsSinceEpoch(this.point.userBegin * 1000);
    var e = DateTime.fromMillisecondsSinceEpoch(this.point.userEnd * 1000);
    final DateFormat formatter = DateFormat.yMd().add_jm();
    return GestureDetector(
      onTap: null, // TODO: Open Google Maps?
      child: CardWithLabel(
        title: Text(
          FlutterI18n.translate(
            context,
            'matched_result.match_title',
            translationParams: {'index': '${index + 1}'},
          ),
        ),
        child: Container(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.95,
            child: Column(
              children: <Widget>[
                CardWithLabel(
                  title: Text(
                    FlutterI18n.translate(context, 'matched_result.time'),
                  ),
                  child:
                      // TODO: translate this
                      Text('${formatter.format(b)} to ${formatter.format(e)}'),
                  elevation: 0.5,
                ),
                CardWithLabel(
                  title: Text(
                    FlutterI18n.translate(
                        context, 'matched_result.patient_desc'),
                  ),
                  child: Text(this.point.patientDesc),
                  elevation: 0.5,
                ),
                CardWithLabel(
                  title: Text(
                    FlutterI18n.translate(context, 'matched_result.user_desc'),
                  ),
                  child: Text(this.point.userDesc),
                  elevation: 0.5,
                ),
                CardWithLabel(
                  title: Text(
                    FlutterI18n.translate(context, 'matched_result.where'),
                  ),
                  child: Text('${this.point.userLat}, ${this.point.userLng}'),
                  elevation: 0.5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MatchedResultWidget extends StatelessWidget {
  Widget _makeMatchedResultWidget() {
    return Consumer<RecordedLocationCheckerModel>(
      builder: (context, model, child) {
        return CustomScrollView(
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  if (index == 0 && model.matchedPointList.length == 0) {
                    return Card(
                      child: Text(
                        FlutterI18n.translate(
                            context, 'matched_result.message_no_result'),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (index >= model.matchedPointList.length) {
                    return null;
                  }
                  return _MatchedPointWidget(
                    point: model.matchedPointList[index],
                    index: index,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: _makeMatchedResultWidget()),
        RaisedButton(
          child: Text(
            FlutterI18n.translate(context, 'matched_result.check_now'),
          ),
          onPressed: () {
            print('pressed');
            Provider.of<RecordedLocationCheckerModel>(context, listen: false)
                .check();
          },
        ),
        makeOptionalCheckerStatusWidget(),
      ],
      mainAxisAlignment: MainAxisAlignment.end,
    );
  }
}
