import 'dart:ui';

import 'package:covid19/notifiers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';

class SettingsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsModel>(
      builder: (context, model, child) {
        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(children: [
              Text(
                FlutterI18n.translate(context, 'settings.locale'),
                textAlign: TextAlign.center,
              ),
              DropdownButton<Locale>(
                value: model.locale,
                items: AppSettingsModel.supportedLocales.map((locale) {
                  return DropdownMenuItem(
                    value: locale,
                    child:
                    Text(locale.toString()),
                  );
                }).toList(),
                onChanged: (Locale locale) {
                  model.setLocale(context, locale);
                },
              ),
            ]),
            TableRow(children: [
              Text(
                FlutterI18n.translate(context, 'settings.periodic_check'),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [Consumer<RecordedLocationCheckerModel>(
                  builder: (context, model, child) {
                    if (model.isRunning == null) {
                      return Switch(
                        value: true,
                        onChanged: null,
                      );
                    }
                    return Switch(
                      value: model.isRunning,
                      onChanged: (_) {
                        model.togglePerioidChecker();
                      },
                    );
                  },
                )],
              ),
            ]),
          ],
        );
      },
    );
  }
}
