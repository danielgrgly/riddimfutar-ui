import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

final String assetName = 'assets/svg/logo.svg';
final Widget svgIcon = SvgPicture.asset(assetName,
    color: Colors.red, semanticsLabel: 'A red up arrow');

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[svgIcon, Text("Hey hi hello!")],
      ),
    );
  }
}
