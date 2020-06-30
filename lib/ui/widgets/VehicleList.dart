import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import '../../core/models/Vehicle.dart';
import '../screens/futar.dart';
import "./Loading.dart";
import './NoVehiclesAround.dart';
import './VehicleCard.dart';

class VehicleList extends StatelessWidget {
  VehicleList({this.location});

  final LocationData location;

  void selectVehicle(BuildContext context, Vehicle vehicle) {
    Navigator.pushNamed(
      context,
      "/futar",
      arguments: FutarArguments(vehicle.tripId, location),
    );
  }

  Future<dynamic> fetchVehicles(double lat, double lon) async {
    final response = await http.get(
      'https://riddimfutar.ey.r.appspot.com/api/v1/vehicles?lat=$lat&lon=$lon',
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

          return vehicleList.length > 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Válassz járatot!",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22),
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
                  ),
                )
              : NoVehiclesAround();
        } else {
          return Loading();
        }
      },
    );
  }
}
