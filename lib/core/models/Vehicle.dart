import 'package:flutter/material.dart';

Color fromHex(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

enum VehicleType { BUS, TRAM, TROLLEY, NIGHT }

VehicleType vehicleFromHex(String hex) {
  switch (hex) {
    case "009FE3":
      return VehicleType.BUS;
    case "FFD800":
      return VehicleType.TRAM;
    case "FF1609":
      return VehicleType.TROLLEY;
    case "1E1E1E":
      return VehicleType.NIGHT;
    default:
      return VehicleType.BUS;
  }
}

String iconPath(VehicleType type) {
  switch (type) {
    case VehicleType.BUS:
      return "assets/svg/bkk_bus.svg";
    case VehicleType.TRAM:
      return "assets/svg/bkk_tram.svg";
    case VehicleType.TROLLEY:
      return "assets/svg/bkk_trolley.svg";
    case VehicleType.NIGHT:
      return "assets/svg/bkk_night.svg";
    default:
      return "assets/svg/bkk_bus.svg";
  }
}

class Vehicle {
  double lat;
  double lon;
  int bearing;
  String licensePlate;
  String label;
  String shortName;
  String tripHeadsign;
  VehicleType type;
  Color color;
  String tripId;

  Vehicle({
    this.lat,
    this.lon,
    this.bearing,
    this.licensePlate,
    this.label,
    this.shortName,
    this.tripHeadsign,
    this.type,
    this.color,
    this.tripId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      lat: json['vehicle']['location']['lat'],
      lon: json['vehicle']['location']['lon'],
      bearing: json['vehicle']['bearing'],
      licensePlate: json['vehicle']['licensePlate'],
      label: json['vehicle']['label'],
      shortName: json['trip']['shortName'],
      tripHeadsign: json['trip']['tripHeadsign'],
      type: vehicleFromHex(json['trip']['color']),
      color: fromHex(json['trip']['color']),
      tripId: json['trip']['tripId'],
    );
  }
}
