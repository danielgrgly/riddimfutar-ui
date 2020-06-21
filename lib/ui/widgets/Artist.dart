import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Artist extends StatelessWidget {
  final Color color;
  final String name;

  Artist({this.color, this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        children: <Widget>[
          SizedBox(
            height: 100,
            child: SvgPicture.asset(
              "assets/svg/artist.svg",
              semanticsLabel: 'artist background',
              color: Color.fromRGBO(70, 71, 112, 1),
            ),
          ),
          Column(
            children: <Widget>[
              Text(
                "Jelenlegi musorvezeto:",
                style: TextStyle(
                  fontFamily: "RoadRage",
                  fontSize: 20,
                  color: color,
                ),
              ),
              Text(name),
            ],
          ),
        ],
      ),
    );
  }
}
