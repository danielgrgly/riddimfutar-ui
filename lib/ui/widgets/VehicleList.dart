import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riddimfutar/ui/screens/futar.dart';

import '../../core/models/Vehicle.dart';
import './VehicleCard.dart';
import "./Loading.dart";

class VehicleList extends StatelessWidget {
  VehicleList({this.location});

  final dynamic location;

  void selectVehicle(BuildContext context, Vehicle vehicle) {
    Navigator.pushNamed(
      context,
      "/futar",
      arguments: FutarArguments(vehicle.tripId),
    );
  }

  Future<dynamic> fetchVehicles(double lat, double lon) async {
    final response = await http.get(
      'http://localhost:8080/api/v1/vehicles?lat=$lat&lon=$lon',
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchVehicles(location.latitude, location.longitude),
      // future: fetchVehicles(47.496652, 19.070190),
      builder: (context, vehicles) {
        if (vehicles.data != null) {
          List<Vehicle> vehicleList =
              vehicles.data.map<Vehicle>((i) => Vehicle.fromJson(i)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Válassz járatot!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              Text(
                "A közeledben levő aktív BKK járműveket listázzuk.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(
                height: 14,
              ),
              ...vehicleList.map(
                (Vehicle vehicle) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    selectVehicle(context, vehicle);
                  },
                  child: VehicleCard(vehicle),
                ),
              )
            ],
          );
        } else {
          return Loading();
        }
      },
    );
  }
}
