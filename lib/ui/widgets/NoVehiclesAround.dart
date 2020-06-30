import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

final String assetName = 'assets/svg/no_vehicles.svg';
final Widget budapestSvg = SvgPicture.asset(
  assetName,
  semanticsLabel: 'Busz hiba illusztráció',
);

class NoVehiclesAround extends StatelessWidget {
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
            "Nincs a közeledben járat!",
            style: TextStyle(
              fontFamily: "RoadRage",
              fontSize: 24,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            "Úgy néz ki, nincs a környékeden egy jármű sem ami szolgálatot teljesítene.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(
            height: 4,
          ),
          Text(
            "Ne felejtsd, az app csak buszokkal, villamosokkal, trolikkal, éjszakai járatokkal és pótlókkal (metrópótló, hévpótló) működik.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
