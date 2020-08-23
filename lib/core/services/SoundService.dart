import 'dart:convert';
import 'dart:async';
import 'dart:core';

import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import "../utils.dart";
import "../models/MusicDetails.dart";
import "../models/TripDetails.dart";
// import "../models/WaveformData.dart";

AudioPlayer _mainPlayer = AudioPlayer();

ConcatenatingAudioSource _audioSource = ConcatenatingAudioSource(
  children: [
    AudioSource.uri(
      Uri.parse("https://storage.googleapis.com/futar/EF-udv.mp3"),
    ),
  ],
);

Location _location = Location();

class SoundService {
  TripDetails tripData;
  MusicDetails musicData;
  int stopSequence;
  Function updateStop;
  Function endTrip;
  Function setArtist;
  // WaveformData _rawWaveformData;
  int percent;
  int reachedMusicIndex;
  int reachedStopIndex;

  SoundService(
    TripDetails trip,
    LocationData userLocation,
    Function updateStop,
    Function endTrip,
    Function setArtist,
  ) {
    this.tripData = trip;
    this.stopSequence = 0;
    this.updateStop = updateStop;
    this.endTrip = endTrip;
    this.setArtist = setArtist;
    this.reachedMusicIndex = -1;
    this.reachedStopIndex = -1;
    this.percent = 0;

    this._init();
  }

  void _init() async {
    AudioPlayer.setIosCategory(IosCategory.playback);

    await _mainPlayer.load(_audioSource);
    await _updateSequence();
    await _fetchMusic();

    _sequence(0);

    _location.onLocationChanged.listen((event) {
      _updateLocation(event);
    });

    _mainPlayer.positionStream.listen((event) {
      if (event.inMilliseconds - 500 ==
          _mainPlayer.duration.inMilliseconds - 500) {
        _sequence(percent);
        _loop();
      }
    });

    _mainPlayer.play();
  }

  Future<void> _updateSequence() async {
    LocationData location = await _location.getLocation();

    final List<double> distances = this
        .tripData
        .stops
        .map(
          (stop) => calculateDistance(
            stop.lat,
            stop.lon,
            location.latitude,
            location.longitude,
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

    this.stopSequence = smallestIndex + 1;

    updateStop(this.stopSequence);
  }

  void _updateLocation(LocationData location) async {
    print("_updateLocation =============================");
    print("stopSequence: $stopSequence; percent: $percent");

    // distance between two stops
    double stopDist = calculateDistance(
      tripData.stops[stopSequence - 1].lat,
      tripData.stops[stopSequence - 1].lon,
      tripData.stops[stopSequence].lat,
      tripData.stops[stopSequence].lon,
    );

    // distance between user and next stop
    double nextDist = calculateDistance(
      tripData.stops[stopSequence - 1].lat,
      tripData.stops[stopSequence - 1].lon,
      location.latitude,
      location.longitude,
    );

    // stop distance percentage
    this.percent = ((nextDist / stopDist) * 100).toInt();

    print("stopSequence: $stopSequence; percent: $percent");
    print("==============================================");
  }

  void _sequence(int sequencePercent) async {
    final int musicIndex = musicData.files.lastIndexWhere(
      (element) => element.breakpoint <= sequencePercent,
    );

    final String stopFile = "https://storage.googleapis.com/futar/" +
        tripData.stops[stopSequence].fileName;

    if (sequencePercent == 0) {
      _addToSource("https://storage.googleapis.com/futar/EF-kov.mp3");

      // stop name
      _addToSource(stopFile);

      if (tripData.stops.length - 1 < stopSequence + 1) {
        _addToSource("https://storage.googleapis.com/futar/EF-veg.mp3");
      }

      _addMusic(musicIndex);
    } else if (sequencePercent >= 95 && reachedStopIndex < stopSequence) {
      reachedStopIndex = stopSequence;

      // stop name
      _addToSource(stopFile);
      // music file
      _addToSource(musicData.files.last.pathURL);

      if (tripData.stops.length - 1 >= stopSequence + 1) {
        print("yea i should come");
        await _updateSequence();
        await _fetchMusic();
        _sequence(0);
      } else {
        _addToSource("https://storage.googleapis.com/futar/EF-veg.mp3");
        _addToSource("https://storage.googleapis.com/futar/EF-visz.mp3");
      }
    } else {
      _addMusic(musicIndex);
    }
  }

  void _addMusic(int musicIndex) {
    print("_addMusic: $musicIndex");
    final MusicFile music = musicData.files[musicIndex];

    if (musicIndex > 0 && reachedMusicIndex < musicIndex) {
      final MusicFile previousMusic = musicData.files[musicIndex - 1];
      if (!previousMusic.loopable &&
          !_checkIfSourceContains(previousMusic.pathURL)) {
        _addToSource(previousMusic.pathURL);
      }
    }

    if (!_checkIfSourceContains(music.pathURL)) {
      reachedMusicIndex = musicIndex;
      _addToSource(music.pathURL);
    }
  }

  void _loop() {
    print("_loop");
    if (_getCurrentUri() == "https://storage.googleapis.com/futar/EF-kov.mp3") {
      updateStop(stopSequence);
      setArtist(musicData.artist);
    }

    if (_getCurrentUri() ==
        "https://storage.googleapis.com/futar/EF-visz.mp3") {
      _audioSource.children.removeRange(0, _audioSource.children.length - 1);

      endTrip();
    }

    if (_mainPlayer.currentIndex == _audioSource.children.length - 1) {
      print("running out of tunes, re-add current");
      _addToSource(_getCurrentUri());
    }
  }

  Future<dynamic> _fetchMusic() async {
    print("_fetchMusic");
    final String genre = tripData.stops[stopSequence].musicOverride ?? "riddim";
    final response = await http.get(
      'https://riddimfutar.ey.r.appspot.com/api/v1/music/$genre',
    );

    if (response.statusCode == 200) {
      reachedMusicIndex = -1;
      musicData = MusicDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch music');
    }
  }

  void _addToSource(String uri) {
    print("_addToSource: $uri");
    print("PRINT OUT EVERYTHING IN AUDIOSOURCE:");
    _audioSource.children.forEach((element) {
      print((element as UriAudioSource).uri);
    });
    print("====================================");
    _audioSource.add(
      AudioSource.uri(
        Uri.parse(uri),
      ),
    );
  }

  bool _checkIfSourceContains(String uri) {
    print("_checkIfSourceContains: $uri");

    List<String> uris = _audioSource.children
        .map((item) => (item as UriAudioSource).uri.toString())
        .toList();

    return uris.contains(uri);
  }

  String _getCurrentUri() {
    print("_getCurrentUri");
    return (_audioSource.children[_mainPlayer.currentIndex] as UriAudioSource)
        .uri
        .toString();
  }

  // Stream<int> waveformStream() async* {
  //   int i = 0;
  //   while (true) {
  //     await Future.delayed(Duration(milliseconds: 10));
  //     if (_rawWaveformData != null) {
  //       i += 10;

  //       if (i >= _rawWaveformData.data.length) {
  //         i = 0;
  //       }

  //       yield _rawWaveformData.data[i].abs();
  //     } else {
  //       yield 0;
  //     }
  //   }
  // }

  void dispose() {
    _mainPlayer.stop();
    _mainPlayer.dispose();

    _mainPlayer = AudioPlayer();

    _audioSource = ConcatenatingAudioSource(
      children: [
        AudioSource.uri(
          Uri.parse("https://storage.googleapis.com/futar/EF-udv.mp3"),
        ),
      ],
    );

    _location = Location();

    this.tripData = null;
    this.musicData = null;
    this.stopSequence = 0;
    this.updateStop = null;
    this.endTrip = null;
    this.setArtist = null;
    this.reachedMusicIndex = -1;
    this.reachedStopIndex = -1;
  }
}
