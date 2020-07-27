import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import '../../core/models/Vehicle.dart';
import '../screens/futar.dart';
import "./Loading.dart";
import './NoVehiclesAround.dart';
import './VehicleCard.dart';

class VehicleList extends StatefulWidget {
  const VehicleList({
    GlobalKey<VehicleListState> key,
    this.location,
  }) : super(key: key);

  final LocationData location;

  @override
  VehicleListState createState() => VehicleListState();
}

class VehicleListState extends State<VehicleList> {
  List<Vehicle> vehicleList;
  bool fetching = true;

  @override
  void initState() {
    fetchVehicles();
    super.initState();
  }

  void selectVehicle(BuildContext context, Vehicle vehicle) {
    Navigator.pushNamed(
      context,
      "/futar",
      arguments: FutarArguments(vehicle.tripId, widget.location),
    );
  }

  Future<void> fetchVehicles() async {
    setState(() {
      fetching = true;
    });

    double lat = widget.location.latitude;
    double lon = widget.location.longitude;

    final response = await http.get(
      'https://riddimfutar.ey.r.appspot.com/api/v1/vehicles?lat=$lat&lon=$lon',
    );

    if (response.statusCode == 200) {
      setState(() {
        vehicleList = json
            .decode(response.body)
            .map<Vehicle>((i) => Vehicle.fromJson(i))
            .toList();

        fetching = false;
      });
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  @override
  Widget build(BuildContext context) {
    return fetching
        ? Loading()
        : vehicleList.length > 0
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Válassz járatot!",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
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
                    ),
                  ],
                ),
              )
            : NoVehiclesAround();
  }
}
