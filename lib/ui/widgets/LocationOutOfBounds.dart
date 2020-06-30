import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

final String assetName = 'assets/svg/budapest.svg';
final Widget budapestSvg = SvgPicture.asset(
  assetName,
  semanticsLabel: 'Budapest illusztráció',
);

class LocationOutOfBounds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34.0),
      child: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          budapestSvg,
          SizedBox(
            height: 24,
          ),
          Text(
            "Irány vissza Budapest!",
            style: TextStyle(
              fontFamily: "RoadRage",
              fontSize: 24,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            "Az app csak a BKK szolgáltatási területén belül működik.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
