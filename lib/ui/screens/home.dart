import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

final String assetName = 'assets/svg/logo.svg';
final Widget logo =
    SvgPicture.asset(assetName, semanticsLabel: 'RIDDIMFUTÁR logo');

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: logo,
      ),
      body: Column(
        children: <Widget>[Text("Hey hi hello!")],
      ),
    );
  }
}
