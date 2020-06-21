import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import "../../core/models/TripDetails.dart";
import "../widgets/Loading.dart";
import "../widgets/FutarDisplay.dart";
import "../widgets/Visualizer.dart";

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
                FutarDisplay(
                  trip: trip,
                ),
                Visualizer(
                  trip: trip,
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
