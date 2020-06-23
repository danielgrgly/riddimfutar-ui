import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import "../../core/models/TripDetails.dart";
import "../widgets/Loading.dart";
import "../widgets/FutarDisplay.dart";
import "../widgets/Visualizer.dart";
import "../widgets/Artist.dart";

final String assetName = 'assets/svg/logo.svg';
final Widget logo = SvgPicture.asset(
  assetName,
  semanticsLabel: 'RIDDIMFUTAR logo',
);

AudioCache riddimCache = AudioCache();
AudioCache futarCache = AudioCache();
AudioPlayer riddimPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
AudioPlayer futarPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);

class FutarArguments {
  final String tripId;

  FutarArguments(this.tripId);
}

class Futar extends StatelessWidget {
  void nextStop(String fileName) async {
    int result = await futarPlayer
        .play('https://storage.googleapis.com/futar/${fileName}');
    if (result == 1) {
      print("played");
      // success
    }
  }

  Future<dynamic> fetchDetails(String id) async {
    print('https://riddimfutar.ey.r.appspot.com/api/v1/vehicle?id=$id');

    // https://riddimfutar.ey.r.appspot.com/api/v1/vehicle

    final response = await http.get(
      'https://riddimfutar.ey.r.appspot.com/api/v1/vehicle?id=$id',
    );

    print(response);

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
            nextStop(trip.stops[2].fileName);

            return Stack(
              children: <Widget>[
                Center(
                  child: Visualizer(
                    trip: trip,
                  ),
                ),
                Column(
                  children: <Widget>[
                    FutarDisplay(
                      trip: trip,
                    ),
                    Spacer(),
                    Artist(color: trip.color, name: "Lil Tango"),
                    SizedBox(
                      height: 24,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).systemGestureInsets.bottom +
                                30,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("ride powered by"),
                          SizedBox(
                            height: 40,
                            width: 200,
                            child: logo,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            );
          } else {
            return Text("fetchdetails...");
          }
        },
      ),
    );
  }
}
