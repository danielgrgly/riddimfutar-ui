import 'package:flutter/material.dart';

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
    return MaterialApp(
      title: "Budipest",
      theme: ThemeData(
        primarySwatch: black,
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'OpenSans',
            ),
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
