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
final Throttling thr1 = new Throttling(duration: Duration(seconds: 1));
final Throttling thr5 = new Throttling(duration: Duration(seconds: 5));
final Location _location = new Location();

Future<dynamic> fetchPercent(String id) async {
  final response = await http.get(
    'https://riddimfutar.ey.r.appspot.com/api/v1/percents/$id',
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
  String tripId;

  SoundService(
    TripDetails trip,
    String tripId,
    void updateStop,
    void endTrip,
  ) {
    print("xd!!!");

    this.tripId = tripId;
    this.tripData = trip;
    this.nextQueue = new List<String>();

    mainPlayer.setReleaseMode(ReleaseMode.STOP);

    fetchMusic();

    // welcome onboard!
    nextQueue.add("https://storage.googleapis.com/futar/EF-u%CC%88dv.mp3");

    _location.onLocationChanged.listen((LocationData location) async {
      thr5.throttle(() async {
        checkBreakpoint(location);
      });
    });

    mainPlayer.onPlayerCompletion.listen((event) {
      this.listenSounds();
    });
  }

  void checkBreakpoint(LocationData location) async {
    final data = await fetchPercent(this.tripId);
    final percent = data["stopDistancePercent"];
    final sequence = data["stopSequence"];

    print(percent);
    print(breakpoints[0]);

    if (percent >= breakpoints[0]) {
      reachBreakpoint(percent, sequence);
    } else {
      print("breakpoint not reached yet...");
    }
  }

  void reachBreakpoint(int percent, int sequence) {
    print("breakpoint reached");

    final String musicFile = "https://storage.googleapis.com/riddim/riddim/0/" +
        musicData.files
            .where((element) => element.breakpoint == breakpoints[0])
            .toList()[0]
            .fileName;

    final String stopFile = "https://storage.googleapis.com/futar/" +
        this.tripData.stops[sequence].fileName;

    if (percent == 0) {
      nextQueue.add("https://storage.googleapis.com/futar/EF-ko%CC%88v.mp3");
      // stop name
      nextQueue.add(stopFile);
      // music file
      nextQueue.add(musicFile);
    } else if (percent == 100) {
      // stop name
      nextQueue.add(stopFile);
      // music file
      nextQueue.add(musicFile);
    } else {
      nextQueue.add(musicFile);
    }

    print(nextQueue);

    breakpoints.removeAt(0);
  }

  void listenSounds() async {
    print("i listen");
    if (nextQueue.length > 1) {
      print("i squash");
      play(nextQueue[1], true);
      // nextQueue.removeAt(0);
    } else {
      print("i sleep");
      play(nextQueue[0], false);
    }
  }

  Future<dynamic> fetchMusic() async {
    final response = await http.get(
      'https://riddimfutar.ey.r.appspot.com/api/v1/music/riddim',
    );

    if (response.statusCode == 200) {
      this.musicData = MusicDetails.fromJson(json.decode(response.body));
      this.breakpoints =
          musicData.files.map((MusicFile file) => file.breakpoint).toList();
      this.listenSounds();
      this.reachBreakpoint(0, 0);
    } else {
      throw Exception('Failed to load vehicle percentage');
    }
  }

  void play(String sound, bool shouldDelete) async {
    print("playing: $sound");

    await mainPlayer.play(sound);

    if(shouldDelete) {
      print("=== this.nextQueue ===");
      print(this.nextQueue);
      this.nextQueue.removeAt(0);
      print(this.nextQueue);
      print("===/===");
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
