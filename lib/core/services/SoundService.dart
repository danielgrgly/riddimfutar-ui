import 'dart:convert';
import 'dart:async';
import 'dart:core';

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
  Function setArtist;
  Map<String, String> cacheMap;
  WaveformData _rawWaveformData;
  int reachedIndex;

  SoundService(
    TripDetails trip,
    String tripId,
    LocationData userLocation,
    Function updateStop,
    Function endTrip,
    Function setArtist,
  ) {
    this.tripId = tripId;
    this.tripData = trip;
    this.sequence = 0;
    this.nextQueue = List<String>();
    this.cacheMap = new Map<String, String>();
    this.updateStop = updateStop;
    this.endTrip = endTrip;
    this.setArtist = setArtist;
    this.reachedIndex = -1;

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
    setArtist(musicData.artist);
    _reachBreakpoint(0);
    _listenSounds();

    Timer.periodic(
      Duration(seconds: 3),
      (Timer t) => _checkBreakpoint(),
    );

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

  void _checkBreakpoint() async {
    final LocationData location = await _location.getLocation();

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
    int percent = ((nextDist / stopDist) * 100).toInt();

    final int musicIndex = musicData.files.lastIndexWhere(
      (element) => element.breakpoint <= percent,
    );

    if (musicIndex > reachedIndex) {
      reachedIndex = musicIndex;
      _reachBreakpoint(percent);
    }
  }

  void _reachBreakpoint(int percent) async {
    final int musicIndex = musicData.files.lastIndexWhere(
      (element) => element.breakpoint <= percent,
    );

    final String stopFile = "https://storage.googleapis.com/futar/" +
        tripData.stops[sequence].fileName;

    if (percent == 0) {
      nextQueue.add("https://storage.googleapis.com/futar/EF-kov.mp3");
      // stop name
      nextQueue.add(stopFile);

      if (tripData.stops.length - 1 < sequence + 1) {
        nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
      }

      _addMusic(musicIndex);
    } else if (percent >= 95) {
      // stop name
      nextQueue.add(stopFile);
      // music file
      nextQueue.add(this.musicData.files.last.pathURL);

      if (tripData.stops.length - 1 >= sequence + 1) {
        print("yea i should come");
        sequence += 1;
        await _fetchMusic();
        _reachBreakpoint(0);
      } else {
        nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
        nextQueue.add("https://storage.googleapis.com/futar/EF-visz.mp3");
      }
    } else {
      _addMusic(musicIndex);
    }
  }

  void _addMusic(int musicIndex) {
    final MusicFile music = musicData.files[musicIndex];

    if (musicIndex > 0) {
      final MusicFile previousMusic = musicData.files[musicIndex - 1];
      if (!previousMusic.loopable &&
          !nextQueue.contains(previousMusic.pathURL)) {
        nextQueue.add(previousMusic.pathURL);
      }
    }

    if (!nextQueue.contains(music.pathURL)) {
      nextQueue.add(music.pathURL);
    }
  }

  void _listenSounds() {
    print("listensounds... queue: $nextQueue");

    if (nextQueue.length > 1) {
      nextQueue.removeAt(0);
    }

    _play(nextQueue[0]);

    if (nextQueue[0] == "https://storage.googleapis.com/futar/EF-kov.mp3") {
      updateStop(sequence);
      setArtist(musicData.artist);
    }

    if (nextQueue[0] == "https://storage.googleapis.com/futar/EF-visz.mp3") {
      nextQueue = [];
      endTrip();
    }
  }

  Future<dynamic> _fetchMusic() async {
    final String genre = tripData.stops[sequence].musicOverride ?? "riddim";
    final response = await http.get(
      'https://riddimfutar.ey.r.appspot.com/api/v1/music/$genre',
    );

    if (response.statusCode == 200) {
      print("200!!!");
      reachedIndex = -1;
      this.musicData = MusicDetails.fromJson(json.decode(response.body));
      this.musicData.files.forEach((element) async {
        _cacheFile(element.pathURL);
      });
      print("HEYOOOOOOO");
    } else {
      print("MEH!!!");
      throw Exception('Failed to fetch music');
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

      // _rawWaveformData = null;
    } else {
      delay = 25;

      // final MusicFile music = musicData.files[musicData.files.lastIndexWhere(
      //   (element) => element.pathURL == url,
      // )];

      // _rawWaveformData = music.waveform;
    }

    Future.delayed(Duration(milliseconds: duration.inMilliseconds - delay), () {
      _listenSounds();
    });
  }

  Stream<int> waveformStream() async* {
    int i = 0;
    while (true) {
      await Future.delayed(Duration(milliseconds: 10));
      if (_rawWaveformData != null) {
        i += 10;

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

    this.tripId = null;
    this.tripData = null;
    this.sequence = 0;
    this.nextQueue = List<String>();
    this.cacheMap = new Map<String, String>();
    this.updateStop = null;
    this.endTrip = null;
  }
}

// import 'dart:convert';
// import 'dart:async';
// import 'dart:core';

// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:location/location.dart';
// import 'package:http/http.dart' as http;
// import "package:just_audio/just_audio.dart";
// import 'package:throttling/throttling.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';

// import '../../core/models/WaveformData.dart';
// import "../../core/utils.dart";
// import "../../core/models/MusicDetails.dart";
// import "../../core/models/TripDetails.dart";

// Timer _timer;
// final _mainPlayer1 = AudioPlayer();
// final _mainPlayer2 = AudioPlayer();
// final Throttling _thr3 = Throttling(duration: Duration(seconds: 3));
// final Location _location = Location();

// class SoundCacheManager extends BaseCacheManager {
//   static const key = "soundCache";

//   static SoundCacheManager _instance;

//   factory SoundCacheManager() {
//     if (_instance == null) {
//       _instance = new SoundCacheManager._();
//     }
//     return _instance;
//   }

//   SoundCacheManager._()
//       : super(
//           key,
//           maxAgeCacheObject: Duration(days: 30),
//           maxNrOfCacheObjects: 80,
//         );

//   @override
//   Future<String> getFilePath() async {
//     var directory = await getTemporaryDirectory();
//     return path.join(directory.path, key);
//   }
// }

// class SoundService {
//   TripDetails tripData;
//   MusicDetails musicData;
//   List<String> nextQueue;
//   String tripId;
//   int sequence;
//   Function updateStop;
//   Function endTrip;
//   Map<String, String> cacheMap;
//   WaveformData _rawWaveformData;
//   int reachedIndex;
//   int playIndex;

//   SoundService(
//     TripDetails trip,
//     String tripId,
//     LocationData userLocation,
//     Function updateStop,
//     Function endTrip,
//   ) {
//     this.tripId = tripId;
//     this.tripData = trip;
//     this.sequence = 0;
//     this.nextQueue = List<String>();
//     this.cacheMap = new Map<String, String>();
//     this.updateStop = updateStop;
//     this.endTrip = endTrip;
//     this.reachedIndex = -1;
//     this.playIndex = 0;

//     final List<double> distances = this
//         .tripData
//         .stops
//         .map(
//           (stop) => calculateDistance(
//             stop.lat,
//             stop.lon,
//             userLocation.latitude,
//             userLocation.longitude,
//           ),
//         )
//         .toList();

//     double smallestValue = distances[0];
//     int smallestIndex = 0;

//     for (int i = 0; i < distances.length; i++) {
//       if (distances[i] < smallestValue) {
//         smallestValue = distances[i];
//         smallestIndex = i;
//       }
//     }

//     sequence = smallestIndex + 1;

//     _init();
//   }

//   void _init() async {
//     // welcome onboard!
//     // add twice because the initial one gets removed
//     nextQueue.add("https://storage.googleapis.com/futar/EF-udv.mp3");

//     String path =
//         await _retrievePath("https://storage.googleapis.com/futar/EF-udv.mp3");
//     _mainPlayer1.setFilePath(path);

//     await _fetchMusic();
//     updateStop(sequence);
//     _reachBreakpoint(0);
//     _listenSounds();

//     Timer.periodic(
//       Duration(seconds: 3),
//       (Timer t) => _checkBreakpoint(),
//     );

//     // DEMO CODE
//     // for testing purposes
//     // uncomment this (and comment the previous) when trying to test the FUTAR service
//     // int percent = 0;
//     // _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
//     //   percent += 3;
//     //   if (percent >= 100) {
//     //     percent = 0;
//     //   }
//     //   _checkBreakpoint(percent);
//     // });
//   }

//   void _checkBreakpoint() async {
//     final LocationData location = await _location.getLocation();

//     // distance between two stops
//     double stopDist = calculateDistance(
//       tripData.stops[sequence - 1].lat,
//       tripData.stops[sequence - 1].lon,
//       tripData.stops[sequence].lat,
//       tripData.stops[sequence].lon,
//     );

//     // distance between user and next stop
//     double nextDist = calculateDistance(
//       tripData.stops[sequence - 1].lat,
//       tripData.stops[sequence - 1].lon,
//       location.latitude,
//       location.longitude,
//     );

//     // stop distance percentage
//     int percent = ((nextDist / stopDist) * 100).toInt();

//     final int musicIndex = musicData.files.lastIndexWhere(
//       (element) => element.breakpoint <= percent,
//     );

//     if (musicIndex > reachedIndex) {
//       reachedIndex = musicIndex;
//       _reachBreakpoint(percent);
//     }
//   }

//   void _reachBreakpoint(int percent) async {
//     final int musicIndex = musicData.files.lastIndexWhere(
//       (element) => element.breakpoint <= percent,
//     );
//     final MusicFile music = musicData.files[musicIndex];

//     final String stopFile = "https://storage.googleapis.com/futar/" +
//         this.tripData.stops[sequence].fileName;

//     if (percent == 0) {
//       nextQueue.add("https://storage.googleapis.com/futar/EF-kov.mp3");
//       // stop name
//       nextQueue.add(stopFile);

//       if (tripData.stops.length - 1 < sequence + 1) {
//         nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
//       }

//       if (musicIndex > 0 && !(this.musicData.files[musicIndex - 1].loopable)) {
//         nextQueue.add(musicData.files[musicIndex - 1].pathURL);
//       }

//       // music file
//       nextQueue.add(music.pathURL);
//     } else if (percent >= 95) {
//       // stop name
//       nextQueue.add(stopFile);
//       // music file
//       nextQueue.add(this.musicData.files.last.pathURL);

//       if (tripData.stops.length - 1 >= sequence + 1) {
//         sequence += 1;
//         reachedIndex = -1;
//         playIndex = 0;
//         await _fetchMusic();
//         _reachBreakpoint(0);
//       } else {
//         nextQueue.add("https://storage.googleapis.com/futar/EF-veg.mp3");
//         nextQueue.add("https://storage.googleapis.com/futar/EF-visz.mp3");
//       }
//     } else {
//       if (musicIndex > 0 && !(this.musicData.files[musicIndex - 1].loopable)) {
//         nextQueue.add(musicData.files[musicIndex - 1].pathURL);
//       }

//       nextQueue.add(music.pathURL);
//     }
//   }

//   void _listenSounds() {
//     if (nextQueue.length > 1) {
//       nextQueue.removeAt(0);
//     }

//     _play(nextQueue[0]);

//     if (nextQueue[0] == "https://storage.googleapis.com/futar/EF-kov.mp3") {
//       updateStop(sequence);
//     }

//     if (nextQueue[0] == "https://storage.googleapis.com/futar/EF-visz.mp3") {
//       nextQueue = [];
//       endTrip();
//     }
//   }

//   Future<dynamic> _fetchMusic() async {
//     final response = await http.get(
//       'https://riddimfutar.ey.r.appspot.com/api/v1/music/riddim',
//     );

//     if (response.statusCode == 200) {
//       this.musicData = MusicDetails.fromJson(json.decode(response.body));
//       this.musicData.files.forEach((element) async {
//         _cacheFile(element.pathURL);
//       });
//     } else {
//       throw Exception('Failed to load vehicle percentage');
//     }
//   }

//   void _cacheFile(String url) async {
//     final file = await SoundCacheManager().downloadFile(url);
//     cacheMap[url] = file.file.path;
//   }

//   Future<String> _retrievePath(String url) async {
//     if (cacheMap[url] != null) {
//       return cacheMap[url];
//     } else {
//       final file = await SoundCacheManager().getSingleFile(url);
//       return file.path;
//     }
//   }

//   void _play(String url) async {
//     print("RETRIEVEPATH=====================");
//     print(new DateTime.now());
//     String path = await _retrievePath(url);
//     print(new DateTime.now());
//     print("RETRIEVEPATH=====================");
//     Duration duration;

//     if (playIndex % 2 == 0) {
//       _mainPlayer2.setFilePath(path);
//       print("=====================");
//       print(new DateTime.now());
//       await _mainPlayer1.play();
//       print(new DateTime.now());
//       print("=====================");
//       _listenSounds();
//     } else {
//       _mainPlayer1.setFilePath(path);
//       print("=====================");
//       print(new DateTime.now());
//       await _mainPlayer2.play();
//       print(new DateTime.now());
//       print("=====================");
//       _listenSounds();
//     }

//     playIndex++;

//     // int delay = 0;

//     // if (url.contains("futar")) {
//     //   // delay = -500;

//     //   _rawWaveformData = null;
//     // } else {
//     //   // delay = 0;

//     //   final MusicFile music = musicData.files[musicData.files.lastIndexWhere(
//     //     (element) => element.pathURL == url,
//     //   )];

//     //   _rawWaveformData = music.waveform;
//     // }
//   }

//   Stream<int> waveformStream() async* {
//     int i = 0;
//     while (true) {
//       await Future.delayed(Duration(milliseconds: 10));
//       if (_rawWaveformData != null) {
//         i += 10;

//         if (i >= _rawWaveformData.data.length) {
//           i = 0;
//         }

//         yield _rawWaveformData.data[i].abs();
//       } else {
//         yield 0;
//       }
//     }
//   }

//   void destroy() {
//     _mainPlayer1.stop();
//     _mainPlayer2.stop();

//     this.tripId = null;
//     this.tripData = null;
//     this.sequence = 0;
//     this.nextQueue = List<String>();
//     this.cacheMap = new Map<String, String>();
//     this.updateStop = null;
//     this.endTrip = null;
//   }
// }
