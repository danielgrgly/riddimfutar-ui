import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import '../widgets/Loading.dart';
import '../widgets/LocationOutOfBounds.dart';
import '../widgets/RollingText.dart';
import '../widgets/VehicleList.dart';

final String assetName = 'assets/svg/logo.svg';
final Widget logo = SvgPicture.asset(
  assetName,
  semanticsLabel: 'RIDDIMFUTAR logo',
);

final Location _location = new Location();

class Home extends StatelessWidget {
  Home({this.vehicleListKey});

  final GlobalKey<VehicleListState> vehicleListKey;

  Future<dynamic> fetchMeta() async {
    final response =
        await http.get('https://riddimfutar.ey.r.appspot.com/api/v1/metadata');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load metadata');
    }
  }

  Future<void> askPermission() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        print("does not have service enabled");
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        print("denied permission");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: fetchMeta(),
        builder: (context, metadata) {
          if (metadata.data != null) {
            askPermission();

            return FutureBuilder<LocationData>(
              future: _location.getLocation(),
              builder: (context, location) {
                return RefreshIndicator(
                  onRefresh: () async {
                    if (vehicleListKey.currentState != null) {
                      if (!vehicleListKey.currentState.fetching) {
                        vehicleListKey.currentState.fetchVehicles();
                      }
                    }
                  },
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: 34.0),
                    shrinkWrap: true,
                    children: <Widget>[
                      SizedBox(
                        height: 40,
                      ),
                      Center(
                        child: SafeArea(
                          bottom: false,
                          child: SizedBox(
                            child: logo,
                            height: 80,
                            width: 320,
                          ),
                        ),
                      ),
                      location.hasData
                          ? metadata.data["lowerLeftLatitude"] <=
                                      location.data.latitude &&
                                  metadata.data["lowerLeftLongitude"] <=
                                      location.data.longitude &&
                                  metadata.data["upperRightLatitude"] >=
                                      location.data.latitude &&
                                  metadata.data["upperRightLongitude"] >=
                                      location.data.longitude
                              ? Column(
                                  children: <Widget>[
                                    metadata.data["message"] != null
                                        ? RollingText(
                                            text: metadata.data["message"],
                                          )
                                        : null,
                                    VehicleList(
                                      key: vehicleListKey,
                                    ),
                                  ],
                                )
                              : Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: LocationOutOfBounds(),
                                )
                          : Loading("load location")
                    ],
                  ),
                );
              },
            );
          } else {
            return Loading("load metadata");
          }
        },
      ),
    );
  }
}
