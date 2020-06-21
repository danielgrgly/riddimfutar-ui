import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

import "../../core/models/TripDetails.dart";
import "../widgets/Loading.dart";
import '../../core/models/Vehicle.dart';

class FutarArguments {
  final String tripId;

  FutarArguments(this.tripId);
}

class Futar extends StatelessWidget {
  Future<dynamic> fetchDetails(String id) async {
    final response = await http.get(
      'http://localhost:8080/api/v1/vehicle?id=$id',
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load trip details');
    }
  }

  @override
  Widget build(BuildContext context) {
    final FutarArguments args = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      backgroundColor: Color.fromRGBO(33, 32, 70, 1),
      body: FutureBuilder(
        future: fetchDetails(args.tripId),
        builder: (context, data) {
          if (data.data != null) {
            TripDetails trip = TripDetails.fromJson(data.data);
            return Column(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).systemGestureInsets.top + 188,
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
          } else {
            return Loading();
          }
        },
      ),
    );
  }
}
