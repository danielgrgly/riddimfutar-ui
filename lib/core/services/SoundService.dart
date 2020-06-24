import 'dart:convert';
import 'dart:async';
// import 'dart:math' show cos, sqrt, asin;

import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:throttling/throttling.dart';

import "../../core/models/MusicDetails.dart";
import "../../core/models/TripDetails.dart";

Timer _timer;
final AudioPlayer _mainPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
// final AudioPlayer secondaryPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
final Throttling _thr5 = new Throttling(duration: Duration(seconds: 5));
final Location _location = new Location();

Future<dynamic> fetchPercent(String id) async {
  final response = await http.get(
    'http://localhost:8080/api/v1/percents/$id',
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
  Function updateStop;
  Function endTrip;

  SoundService(
    TripDetails trip,
    String tripId,
    Function updateStop,
    Function endTrip,
  ) {
    this.tripId = tripId;
    this.tripData = trip;
    this.nextQueue = new List<String>();
    this.updateStop = updateStop;
    this.endTrip = endTrip;

    _init();
  }

  void _init() async {
    await _fetchMusic();

    // welcome onboard!
    nextQueue.add("https://storage.googleapis.com/futar/EF-udv.mp3");

    final data = await fetchPercent(this.tripId);
    final sequence = data["stopSequence"];
    _reachBreakpoint(0, sequence);

    _listenSounds();

    _timer = Timer.periodic(
      Duration(seconds: 5),
      (Timer t) => _checkBreakpoint(),
    );

    // _location.onLocationChanged.listen((LocationData location) async {
    //   _thr5.throttle(() async {
    //     _checkBreakpoint();
    //   });
    // });

    _mainPlayer.onPlayerCompletion.listen((event) {
      _listenSounds();
    });
  }

  void _checkBreakpoint() async {
    final data = await fetchPercent(this.tripId);
    final percent = data["stopDistancePercent"];
    final sequence = data["stopSequence"];

    if (percent >= breakpoints[0]) {
      _reachBreakpoint(percent, sequence);
    }
  }

  void _reachBreakpoint(int percent, int sequence) {
    print("percent: $percent");
    final index = breakpoints.lastIndexWhere((element) => element <= percent);
    final MusicFile music = musicData.files[index];
    final musicFile =
        "https://storage.googleapis.com/riddim/riddim/0/" + music.fileName;
    final String stopFile = "https://storage.googleapis.com/futar/" +
        this.tripData.stops[sequence].fileName;

    if (percent == 0) {
      print("0");
      nextQueue.add("https://storage.googleapis.com/futar/EF-kov.mp3");
      // stop name
      nextQueue.add(stopFile);
      if (tripData.stops.length - 1 < sequence + 1) {
        nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
      }
      // music file
      nextQueue.add(musicFile);
    } else if (percent == 100) {
      print("100");
      // stop name
      nextQueue.add(stopFile);
      // music file
      nextQueue.add(musicFile);

      print(tripData.stops.length);
      print(sequence);
      if (tripData.stops.length - 1 >= sequence + 1) {
        print("aight sequence");
        _fetchMusic();
        _reachBreakpoint(0, sequence + 1);
        updateStop(sequence + 1);
      } else {
        nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
        nextQueue.add("https://storage.googleapis.com/futar/EF-visz.mp3");
        print("fuck u imma end");
      }
    } else {
      print("nothing special");
      nextQueue.add(musicFile);
    }

    if (!music.loopable) {
      breakpoints.removeAt(index);
      musicData.files.removeAt(index);

      // if (musicData.files.length == index + 1) {
      //   // the next stop!
      //   if (sequence + 1 >= tripData.stops.length) {
      //     // no next stop - end of trip
      //     // this.endTrip();
      //   } else {
      //     // next stop exists
      //     this._fetchMusic();
      //     this._reachBreakpoint(0, sequence + 1);
      //     updateStop;
      //   }
      // } else {
      //   // next file
      final MusicFile nextMusic = musicData.files[index + 1];
      final nextFile = "https://storage.googleapis.com/riddim/riddim/0/" +
          nextMusic.fileName;
      nextQueue.add(nextFile);
      // }
    }
  }

  void _listenSounds() {
    _play(nextQueue[0]);

    if (nextQueue[0] == "https://storage.googleapis.com/futar/EF-visz.mp3") {
      nextQueue = [];
      endTrip();
    }

    if (nextQueue.length > 1) {
      nextQueue.removeAt(0);
    }
  }

  Future<dynamic> _fetchMusic() async {
    final response = await http.get(
      'http://localhost:8080/api/v1/music/riddim',
    );

    if (response.statusCode == 200) {
      this.musicData = MusicDetails.fromJson(json.decode(response.body));
      this.breakpoints =
          musicData.files.map((MusicFile file) => file.breakpoint).toList();
    } else {
      throw Exception('Failed to load vehicle percentage');
    }
  }

  void _play(String sound) async {
    await _mainPlayer.play(sound);
  }
}
