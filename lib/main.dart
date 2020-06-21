import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';

import './ui/screens/home.dart';
import './ui/screens/futar.dart';
import './ui/screens/about.dart';

import './core/constants.dart';

void main() {
  runApp(Riddimfutar());
}

class Riddimfutar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarWhiteForeground(true);

    return MaterialApp(
      title: "Budipest",
      theme: ThemeData(
        primarySwatch: black,
        textTheme: Theme.of(context)
            .textTheme
            .apply(fontFamily: 'OpenSans', bodyColor: Colors.white),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/futar': (context) => Futar(),
        '/about': (context) => About()
      },
    );
  }
}
