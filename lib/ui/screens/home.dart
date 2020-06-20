import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:riddimfutar/ui/widgets/VehicleList.dart';

import '../widgets/Error.dart';
import '../widgets/Loading.dart';
// import '../widgets/VehicleList.dart';

final String assetName = 'assets/svg/logo.svg';
final Widget logo =
    SvgPicture.asset(assetName, semanticsLabel: 'RIDDIMFUTAR logo');

final Location _location = new Location();

class Home extends StatelessWidget {
  Future<dynamic> fetchMeta() async {
    final response =
        await http.get('https://riddimfutar.ey.r.appspot.com/api/v1/metadata');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load metadata');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: EdgeInsets.all(34.0),
        shrinkWrap: true,
        children: <Widget>[
          Center(
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                child: logo,
                height: 120,
                width: 320,
              ),
            ),
          ),
          FutureBuilder(
            future: fetchMeta(),
            builder: (context, metadata) {
              if (metadata.data != null) {
                return StreamBuilder(
                  stream: _location.onLocationChanged,
                  builder: (context, location) {
                    if (location.hasData) {
                      if (metadata.data["lowerLeftLatitude"] <=
                              location.data.latitude &&
                          metadata.data["lowerLeftLongitude"] <=
                              location.data.longitude &&
                          metadata.data["upperRightLatitude"] >=
                              location.data.latitude &&
                          metadata.data["upperRightLongitude"] >=
                              location.data.longitude) {
                        return VehicleList(location: location.data);
                      } else {
                        return Error();
                      }
                    } else {
                      _location.requestPermission();
                      _location.getLocation();
                      return Loading();
                    }
                  },
                );
              } else {
                return Loading();
              }
            },
          ),
        ],
      ),
    );
  }
}
