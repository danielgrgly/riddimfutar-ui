import 'dart:convert';
import 'dart:async';
// import 'dart:math' show cos, sqrt, asin;

import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:throttling/throttling.dart';

import "../../core/models/MusicDetails.dart";
import "../../core/models/TripDetails.dart";

final AudioCache riddimCache = AudioCache();
final AudioCache futarCache = AudioCache();
final AudioPlayer mainPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
final AudioPlayer secondaryPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
final Throttling thr = new Throttling(duration: Duration(seconds: 5));
final Location _location = new Location();

Future<dynamic> fetchPercent(String id) async {
  final response = await http.get(
    'https://riddimfutar.ey.r.appspot.com/api/v1/vehicle/$id/percent',
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load vehicle percentage');
  }
}

class SoundService {
  TripDetails tripData;
  MusicDetails musicData;
  List<int> breakpoints;
  List<String> nextQueue;

  SoundService(
    TripDetails trip,
    MusicDetails music,
    void updateStop,
    void endTrip,
  ) {
    this.musicData = music;
    this.tripData = trip;
    this.breakpoints = musicData.files.map((MusicFile file) => file.breakpoint);

    _location.onLocationChanged.listen((LocationData location) async {
      thr.throttle(() async {
        final data = await fetchPercent(trip.vehicleId);
        final percent = data["percent"];
        // final sequence = data["sequence"];

        if (percent > breakpoints[0]) {
          reachBreakpoint();
        } else {
          print("breakpoint not reached yet...");
        }
      });
    });
  }

  void reachBreakpoint() {
    print("breakpoint reached!");

    nextQueue.add(
      musicData.files
          .where((element) => element.breakpoint == breakpoints[0])
          .toList()[0]
          .fileName,
    );

    print(nextQueue);

    breakpoints.removeAt(0);
  }

  Stream<String> titleStream() async* {
    if (nextQueue[1] != null) {
      yield nextQueue[1];
      nextQueue.removeLast();
    } else {
      yield nextQueue[0];
    }
  }
}

// void nextStop(String fileName) async {
//   int result = await futarPlayer
//       .play('https://storage.googleapis.com/futar/${fileName}');
//   if (result == 1) {
//     print("played");
//     // success
//   }
// }
