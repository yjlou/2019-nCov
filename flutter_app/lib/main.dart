import 'package:covid19/common_widget.dart';
import 'package:covid19/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    child: MyApp(),
    providers: [
      ChangeNotifierProvider(create: (context) => AppSettingsModel()),
      ChangeNotifierProvider(create: (context) => LocationCollectorModel()),
      ChangeNotifierProvider(
          create: (context) => RecordedLocationCheckerModel()),
      ChangeNotifierProvider(create: (context) => AppPageModel())
    ],
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracker',
      localizationsDelegates: [
        FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
          basePath: 'assets/locales',
          fallbackFile: 'assets/locales/en_US.yaml',
          useCountryCode: true,
        )),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      home: OuterWidget(),
//      initialRoute: '/',
//      routes: {
//        '/': (context) => MainWidget(),
//        '/matched_result': (context) => MatchedResultWidget(),
//        '/recorded_location': (context) => RecordedLocationWidget(),
//        '/settings': (context) => SettingsWidget(),
//      },
    );
  }
}
