import 'package:flutter/material.dart';
import './Vehicle.dart';

class StopDetails {
  String fileName;
  String name;
  double lat;
  double lon;
  int predictedArrivalTime;

  StopDetails({
    this.fileName,
    this.name,
    this.lat,
    this.lon,
    this.predictedArrivalTime,
  });

  factory StopDetails.fromJson(Map<String, dynamic> json) {
    return StopDetails(
      fileName: json['fileName'],
      lat: json['lat'],
      lon: json['lon'],
      name: json['name'],
      predictedArrivalTime: json['predictedArrivalTime'],
    );
  }
}

class TripDetails {
  // stops
  List<StopDetails> stops;

  // trip
  Color color;
  String name;
  String description;
  VehicleType type;

  // vehicle
  int bearing;
  double lat;
  double lon;
  int stopDistancePercent;
  int stopSequence;
  String vehicleId;

  TripDetails({
    // stops
    this.stops,
    // trip
    this.color,
    this.name,
    this.description,
    this.type,
    // vehicle
    this.bearing,
    this.lat,
    this.lon,
    this.stopDistancePercent,
    this.stopSequence,
    this.vehicleId
  });

  factory TripDetails.fromJson(Map<String, dynamic> json) {
    return TripDetails(
      // stops
      stops: json['stops']
          .map<StopDetails>((i) => StopDetails.fromJson(i))
          .toList(),

      // trip
      color: fromHex(json['trip']['color']),
      name: json['trip']['shortName'],
      description: json['trip']['tripHeadsign'],
      type: vehicleFromHex(json['trip']['color']),

      // vehicle
      bearing: json['vehicle']['bearing'],
      lat: json['vehicle']['location']['lat'],
      lon: json['vehicle']['location']['lon'],
      stopDistancePercent: json['vehicle']['stopDistancePercent'],
      stopSequence: json['vehicle']['stopSequence'],
      vehicleId: json['vehicle']['id'],
    );
  }
}
