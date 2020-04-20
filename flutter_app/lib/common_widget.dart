import 'package:covid19/matched_result_widget.dart';
import 'package:covid19/recorded_location_widget.dart';
import 'package:covid19/settings_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_widget.dart';
import 'notifiers.dart';

class OuterWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return OuterWidgetState();
  }
}

class OuterWidgetState extends State<OuterWidget> {
  final _routes = {
    AppPageEnum.HOME: (context) => MainWidget(),
    AppPageEnum.SETTINGS: (context) => SettingsWidget(),
    AppPageEnum.RECORDED_LOCATION: (context) => RecordedLocationWidget(),
    AppPageEnum.MATCHED_RESULT: (context) => MatchedResultWidget(),
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLocaleModel>(
      builder: (context, model, child) {
        return Localizations.override(
          context: context,
          locale: model.locale,
          child: Scaffold(
            appBar: AppBar(
              title: I18nText('title'),
            ),
            body: Consumer<AppPageModel>(
              builder: (context, model, child) {
                return _routes[model.currentPage](context);
              },
            ),
            bottomNavigationBar: Consumer<AppPageModel>(
              builder: (context, model, child) {
                return BottomNavigationBar(
                  currentIndex: model.currentPage.index,
                  selectedItemColor: Colors.blueAccent,
                  unselectedItemColor: Colors.black,
                  onTap: (int index) {
                    final route = AppPageEnum.values[index];
                    switch (route) {
                      case AppPageEnum.HOME:
                      case AppPageEnum.SETTINGS:
                        Provider.of<AppPageModel>(context, listen: false)
                            .goto(route);
                        break;
                      case AppPageEnum.RECORDED_LOCATION: // Recording
                        toggleRecordLocation(context);
                        break;
                      case AppPageEnum.MATCHED_RESULT:
                        Provider.of<AppPageModel>(context, listen: false)
                            .goto(route);
                        break;
                    }
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      title: I18nText('common.home'),
                    ),
                    BottomNavigationBarItem(
                      icon: Consumer<LocationCollectorModel>(
                        builder: (context, model, child) {
                          return IconButton(
                            icon: model.isRecordingLocation == true
                                ? Icon(
                                    Icons.pause,
                                    color: Colors.black,
                                  )
                                : Icon(
                                    Icons.fiber_manual_record,
                                    color: Colors.red,
                                  ),
                          );
                        },
                      ),
                      title: I18nText('common.records'),
                      // title: Text(FlutterI18n.translate(context, 'common.records')),
                    ),
                    BottomNavigationBarItem(
                      icon: GestureDetector(
                        child: Icon(Icons.assignment),
                        onLongPress: () {
                          showMenu(
                            context: context,
                            position: _buttonMenuPosition(context),
                            items: [
                              PopupMenuItem<int>(
                                child: GestureDetector(
                                  onTap: () {
                                    // close the popup menu.
                                    Navigator.of(context).pop();
                                    Provider.of<RecordedLocationCheckerModel>(
                                      context,
                                      listen: false,
                                    ).check();
                                  },
                                  child: Row(
                                    children: <Widget>[
                                      Icon(Icons.youtube_searched_for),
                                      I18nText('matched_result.check_now')
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      title: I18nText('common.results'),
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      title: I18nText('common.settings'),
                      // title: Text(FlutterI18n.translate(context, 'common.settings')),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class CardWithLabel extends StatelessWidget {
  final Widget title;
  final Widget child;
  final Color labelColor;
  final double elevation;

  CardWithLabel(
      {@required this.title,
      @required this.child,
      this.labelColor: Colors.black26,
      this.elevation: 1.0});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: elevation,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                color: labelColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: title,
            ),
          ),
          Align(
            child: Container(
              child: child,
              padding: EdgeInsets.fromLTRB(0, 25, 0, 0),
            ),
            alignment: Alignment.bottomCenter,
          ),
        ],
      ),
    );
  }
}

Widget makeOptionalCheckerStatusWidget() {
  return Consumer<RecordedLocationCheckerModel>(
    builder: (context, model, child) {
      switch (model.checkerStatus) {
        case RecordedLocationCheckerStatus.IDLE:
          return Container(); // return an empty widget
        case RecordedLocationCheckerStatus.CHECKING:
        case RecordedLocationCheckerStatus.FAILED:
          return CardWithLabel(
            title: I18nText('common.checking'),
            child: Text(
              model.lastCheckerMessage,
              textAlign: TextAlign.left,
            ),
            labelColor:
                model.checkerStatus == RecordedLocationCheckerStatus.FAILED
                    ? Colors.red
                    : Colors.greenAccent,
          );
        default:
          throw Exception('Unknown case, ${model.checkerStatus}');
      }
    },
  );
}

RelativeRect _buttonMenuPosition(BuildContext c) {
  final RenderBox bar = c.findRenderObject();
  final RenderBox overlay = Overlay.of(c).context.findRenderObject();

  final topLeft = bar.localToGlobal(
      bar.size.topLeft(Offset(0, -bar.size.height)),
      ancestor: overlay);
  final topRight = bar.localToGlobal(
      bar.size.topRight(Offset(0, -bar.size.height)),
      ancestor: overlay);
  final offset = Offset.lerp(topLeft, topRight, 0.5);

  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(offset, offset),
    Offset.zero & overlay.size,
  );
//  print(position);
  return position;
}

void toggleRecordLocation(BuildContext context) async {
  const USER_CONSENT_KEY = 'IS_OK_TO_RECORD_LOCATION';
  final preferences = await SharedPreferences.getInstance();
  if (preferences.getBool(USER_CONSENT_KEY) != true) {
    var ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Consumer<AppLocaleModel>(
          builder: (context, model, child) {
            return Localizations.override(
              context: context,
              locale: model.locale,
              child: AlertDialog(
                title: I18nText('common.record_location_title'),
                content: I18nText('common.record_location_message'),
                actions: <Widget>[
                  FlatButton(
                    child: I18nText('confirm'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  FlatButton(
                    child: I18nText('decline'),
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
    if (!ok) {
      return;
    }
    preferences.setBool(USER_CONSENT_KEY, true);
  }

  Provider.of<LocationCollectorModel>(
    context,
    listen: false,
  ).toggleRecordingLocation();
}
