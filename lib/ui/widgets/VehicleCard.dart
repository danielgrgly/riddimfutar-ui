import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/Vehicle.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard(this.vehicle);

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(3.0),
        ),
        gradient: LinearGradient(
          stops: [0.03, 0.03],
          colors: [vehicle.color, Colors.grey[800]],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 34,
              height: 34,
              child: SvgPicture.asset(
                iconPath(vehicle.type),
                semanticsLabel: 'vehicle icon',
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Text(
                "${vehicle.shortName} ▶ ${vehicle.tripHeadsign}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
