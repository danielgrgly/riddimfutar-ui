import 'dart:convert';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;

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

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

class SoundService {
  TripDetails tripData;
  MusicDetails musicData;
  List<String> nextQueue;
  String tripId;
  int sequence;
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
    this.sequence = trip.stopSequence;
    this.nextQueue = new List<String>();
    this.updateStop = updateStop;
    this.endTrip = endTrip;

    _init();
  }

  void _init() async {
    await _fetchMusic();

    // welcome onboard!
    nextQueue.add("https://storage.googleapis.com/futar/EF-udv.mp3");

    _reachBreakpoint(0);

    _listenSounds();

    // _timer = Timer.periodic(
    //   Duration(seconds: 5),
    //   (Timer t) => _checkBreakpoint(),
    // );

    // _location.onLocationChanged.listen((LocationData location) async {
    //   _thr5.throttle(() async {
    //     _checkBreakpoint();
    //   });
    // });

    int percent = 0;

    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      percent += 2;

      if (percent >= 100) {
        percent = 0;
      }

      _checkBreakpoint(percent);
    });

    _mainPlayer.onPlayerCompletion.listen((event) {
      _listenSounds();
    });
  }

  void _checkBreakpoint(int percent) async {
    if (percent >= musicData.files[0].breakpoint) {
      _reachBreakpoint(percent);
    }
    if (percent >= 97) {
      _reachBreakpoint(100);
    }
  }

  void _reachBreakpoint(int percent) async {
    final MusicFile music = musicData.files[0];
    final musicFile =
        "https://storage.googleapis.com/riddim/riddim/0/" + music.fileName;
    final String stopFile = "https://storage.googleapis.com/futar/" +
        this.tripData.stops[sequence].fileName;

    musicData.files.removeAt(0);

    if (percent == 0) {
      nextQueue.add("https://storage.googleapis.com/futar/EF-kov.mp3");
      // stop name
      nextQueue.add(stopFile);
      if (tripData.stops.length - 1 < sequence + 1) {
        nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
      }
      // music file
      nextQueue.add(musicFile);
    } else if (percent >= 97) {
      // stop name
      nextQueue.add(stopFile);
      // music file
      nextQueue.add(musicFile);

      if (tripData.stops.length - 1 >= sequence + 1) {
        sequence++;
        await _fetchMusic();
        _reachBreakpoint(0);
      } else {
        nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
        nextQueue.add("https://storage.googleapis.com/futar/EF-visz.mp3");
      }
    } else {
      nextQueue.add(musicFile);
    }

    // if (!music.loopable) {
    //   // breakpoints.removeAt(index);
    //   // musicData.files.removeAt(index);

    //   // if (musicData.files.length == index + 1) {
    //   //   // the next stop!
    //   //   if (sequence + 1 >= tripData.stops.length) {
    //   //     // no next stop - end of trip
    //   //     // this.endTrip();
    //   //   } else {
    //   //     // next stop exists
    //   //     this._fetchMusic();
    //   //     this._reachBreakpoint(0, sequence + 1);
    //   //     updateStop;
    //   //   }
    //   // } else {
    //   //   // next file
    //   final MusicFile nextMusic = musicData.files[index + 1];
    //   final nextFile = "https://storage.googleapis.com/riddim/riddim/0/" +
    //       nextMusic.fileName;
    //   nextQueue.add(nextFile);
    //   // }
    // }
  }

  void _listenSounds() {
    if (nextQueue.length > 1) {
      nextQueue.removeAt(0);
    }

    _play(nextQueue[0]);

    if (nextQueue[0] == "https://storage.googleapis.com/futar/EF-kov.mp3") {
      updateStop(sequence);
    }

    if (nextQueue[0] == "https://storage.googleapis.com/futar/EF-visz.mp3") {
      nextQueue = [];
      endTrip();
    }
  }

  Future<dynamic> _fetchMusic() async {
    final response = await http.get(
      'http://localhost:8080/api/v1/music/riddim',
    );

    if (response.statusCode == 200) {
      this.musicData = MusicDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load vehicle percentage');
    }
  }

  void _play(String sound) async {
    await _mainPlayer.play(sound);
  }
}
