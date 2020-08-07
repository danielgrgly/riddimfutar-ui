import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import "../../core/models/TripDetails.dart";
import '../../core/models/Vehicle.dart';

class FutarDisplay extends StatelessWidget {
  FutarDisplay({this.trip});

  final TripDetails trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width,
          color: Color.fromRGBO(70, 71, 112, 1),
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 24.0,
              right: 24.0,
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: SvgPicture.asset(
                        iconPath(trip.type),
                        semanticsLabel: 'vehicle icon',
                      ),
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Container(
                      width: 68,
                      height: 34,
                      child: Center(
                        child: Text(
                          trip.name,
                          style: TextStyle(
                            color: trip.type == VehicleType.TRAM
                                ? Color.fromRGBO(43, 41, 41, 1)
                                : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: trip.color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 14,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 30,
                      height: 84,
                      child: SvgPicture.asset(
                        "assets/svg/terminus.svg",
                        semanticsLabel: 'terminus illustration',
                        color: trip.color,
                      ),
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        trip.description,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 30,
                height: 72,
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      width: 30,
                      height: 72,
                      child: SvgPicture.asset(
                        "assets/svg/stop.svg",
                        semanticsLabel: 'stop illustration',
                        color: trip.color,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 48),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: SvgPicture.asset(
                          "assets/svg/dot.svg",
                          semanticsLabel: 'dot for stop illustration',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    trip.stops[trip.stopSequence].name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
