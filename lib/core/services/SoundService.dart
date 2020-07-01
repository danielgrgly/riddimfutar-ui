import 'dart:convert';
import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:riddimfutar/core/models/WaveformData.dart';
import 'package:throttling/throttling.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import "../../core/utils.dart";
import "../../core/models/MusicDetails.dart";
import "../../core/models/TripDetails.dart";

Timer _timer;
final _mainPlayer = AudioPlayer();
final Throttling _thr3 = Throttling(duration: Duration(seconds: 3));
final Location _location = Location();

class SoundCacheManager extends BaseCacheManager {
  static const key = "soundCache";

  static SoundCacheManager _instance;

  factory SoundCacheManager() {
    if (_instance == null) {
      _instance = new SoundCacheManager._();
    }
    return _instance;
  }

  SoundCacheManager._()
      : super(
          key,
          maxAgeCacheObject: Duration(days: 30),
          maxNrOfCacheObjects: 80,
        );

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return path.join(directory.path, key);
  }
}

class SoundService {
  TripDetails tripData;
  MusicDetails musicData;
  List<String> nextQueue;
  String tripId;
  int sequence;
  Function updateStop;
  Function endTrip;
  Map<String, String> cacheMap;
  StreamSubscription _locationStream;
  WaveformData _rawWaveformData;

  SoundService(
    TripDetails trip,
    String tripId,
    LocationData userLocation,
    Function updateStop,
    Function endTrip,
  ) {
    this.tripId = tripId;
    this.tripData = trip;
    this.sequence = 0;
    this.nextQueue = List<String>();
    this.cacheMap = new Map<String, String>();
    this.updateStop = updateStop;
    this.endTrip = endTrip;

    final List<double> distances = this
        .tripData
        .stops
        .map(
          (stop) => calculateDistance(
            stop.lat,
            stop.lon,
            userLocation.latitude,
            userLocation.longitude,
          ),
        )
        .toList();

    double smallestValue = distances[0];
    int smallestIndex = 0;

    for (int i = 0; i < distances.length; i++) {
      if (distances[i] < smallestValue) {
        smallestValue = distances[i];
        smallestIndex = i;
      }
    }

    sequence = smallestIndex + 1;

    _init();
  }

  void _init() async {
    // welcome onboard!
    // add twice because the initial one gets removed
    nextQueue.add("https://storage.googleapis.com/futar/EF-udv.mp3");
    nextQueue.add("https://storage.googleapis.com/futar/EF-udv.mp3");

    await _fetchMusic();
    updateStop(sequence);
    _reachBreakpoint(0);
    _listenSounds();

    _locationStream =
        _location.onLocationChanged.listen((LocationData location) async {
      _thr3.throttle(() async {
        // distance between two stops
        double stopDist = calculateDistance(
          tripData.stops[sequence - 1].lat,
          tripData.stops[sequence - 1].lon,
          tripData.stops[sequence].lat,
          tripData.stops[sequence].lon,
        );

        // distance between user and next stop
        double nextDist = calculateDistance(
          tripData.stops[sequence - 1].lat,
          tripData.stops[sequence - 1].lon,
          location.latitude,
          location.longitude,
        );

        // stop distance percentage
        double percent = (nextDist / stopDist) * 100;

        _checkBreakpoint(percent.toInt());
      });
    });

    // DEMO CODE
    // for testing purposes
    // uncomment this (and comment the previous) when trying to test the FUTAR service
    // int percent = 0;
    // _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
    //   percent += 3;
    //   if (percent >= 100) {
    //     percent = 0;
    //   }
    //   _checkBreakpoint(percent);
    // });
  }

  void _checkBreakpoint(int percent) async {
    if (percent >= musicData.files[0].breakpoint) {
      _reachBreakpoint(percent);
    }
  }

  void _reachBreakpoint(int percent) async {
    final MusicFile music = musicData.files[musicData.files.lastIndexWhere(
      (element) => element.breakpoint <= percent,
    )];
    final String stopFile = "https://storage.googleapis.com/futar/" +
        this.tripData.stops[sequence].fileName;

    if (percent == 0) {
      nextQueue.add("https://storage.googleapis.com/futar/EF-kov.mp3");
      // stop name
      nextQueue.add(stopFile);
      if (tripData.stops.length - 1 < sequence + 1) {
        nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
      }
      // music file
      nextQueue.add(music.pathURL);
    } else if (percent >= 97) {
      // stop name
      nextQueue.add(stopFile);
      // music file
      nextQueue.add(music.pathURL);

      if (tripData.stops.length - 1 >= sequence + 1) {
        sequence += 1;
        await _fetchMusic();
        _reachBreakpoint(0);
      } else {
        nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
        nextQueue.add("https://storage.googleapis.com/futar/EF-visz.mp3");
      }
    } else {
      nextQueue.add(music.pathURL);
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
      'https://riddimfutar.ey.r.appspot.com/api/v1/music/riddim',
    );

    if (response.statusCode == 200) {
      this.musicData = MusicDetails.fromJson(json.decode(response.body));
      this.musicData.files.forEach((element) async {
        _cacheFile(element.pathURL);
      });
    } else {
      throw Exception('Failed to load vehicle percentage');
    }
  }

  void _cacheFile(String url) async {
    final file = await SoundCacheManager().downloadFile(url);
    cacheMap[url] = file.file.path;
  }

  Future<String> _retrievePath(String url) async {
    if (cacheMap[url] != null) {
      return cacheMap[url];
    } else {
      final file = await SoundCacheManager().getSingleFile(url);
      return file.path;
    }
  }

  void _play(String url) async {
    String path = await _retrievePath(url);
    Duration duration = await _mainPlayer.setFilePath(path);
    _mainPlayer.play();

    int delay;

    if (url.contains("futar")) {
      delay = -500;

      _rawWaveformData = null;
    } else {
      delay = 125;

      final MusicFile music = musicData.files[musicData.files.lastIndexWhere(
        (element) => element.pathURL == url,
      )];

      _rawWaveformData = music.waveform;
    }

    Future.delayed(Duration(milliseconds: duration.inMilliseconds - delay), () {
      _listenSounds();
    });
  }

  Stream<int> waveformStream() async* {
    int i = 0;
    while (true) {
      await Future.delayed(Duration(milliseconds: 180));
      if (_rawWaveformData != null) {
        i += 180;

        if (i >= _rawWaveformData.data.length) {
          i = 0;
        }

        yield _rawWaveformData.data[i].abs();
      } else {
        yield 0;
      }
    }
  }

  void destroy() {
    _mainPlayer.stop();
    _locationStream.cancel();

    this.tripId = null;
    this.tripData = null;
    this.sequence = 0;
    this.nextQueue = List<String>();
    this.cacheMap = new Map<String, String>();
    this.updateStop = null;
    this.endTrip = null;
  }
}
