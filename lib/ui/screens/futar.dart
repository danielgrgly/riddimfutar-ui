import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

import "../../core/models/TripDetails.dart";
import "../../core/services/SoundService.dart";
import "../widgets/Loading.dart";
import "../widgets/FutarDisplay.dart";
import "../widgets/Visualizer.dart";
import "../widgets/Artist.dart";

final String assetName = 'assets/svg/logo.svg';
final Widget logo = SvgPicture.asset(
  assetName,
  semanticsLabel: 'RIDDIMFUTAR logo',
);

class FutarArguments {
  final String tripId;
  final LocationData location;

  FutarArguments(this.tripId, this.location);
}

class Futar extends StatefulWidget {
  const Futar({GlobalKey<FutarState> key}) : super(key: key);

  @override
  FutarState createState() => FutarState();
}

class FutarState extends State<Futar> {
  TripDetails trip;
  SoundService sound;

  Future<dynamic> fetchDetails(String id) async {
    final response = await http.get(
      'https://riddimfutar.ey.r.appspot.com/api/v1/vehicle/$id',
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load trip details');
    }
  }

  void asyncInit() async {
    final FutarArguments args = ModalRoute.of(context).settings.arguments;
    final details = await fetchDetails(args.tripId);

    setState(() {
      trip = TripDetails.fromJson(details);
      sound = new SoundService(
        trip,
        args.tripId,
        args.location,
        updateStop,
        endTrip,
      );
    });
  }

  void updateStop(int sequence) {
    setState(() {
      trip.stopSequence = sequence;
    });
  }

  void endTrip() {
    sound.destroy();
    sound = null;
    Navigator.of(context).pop();
    super.dispose();
  }

  @override
  void dispose() {
    sound.destroy();
    sound = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (trip == null) {
      asyncInit();
    }

    return Scaffold(
      backgroundColor: Color.fromRGBO(33, 32, 70, 1),
      body: trip != null
          ? Stack(
              children: <Widget>[
                Center(
                  child: Visualizer(
                    trip: trip,
                    futarKey: widget.key,
                  ),
                ),
                Column(
                  children: <Widget>[
                    FutarDisplay(trip: trip),
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
            )
          : Loading(),
    );
  }
}
