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
  int announcedStopIndex;
  int reachedStopIndex;
  List<String> _allUris;

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
    this.announcedStopIndex = -1;
    this.reachedStopIndex = -2;
    this.percent = 0;
    this._allUris = List<String>();

    this._init();
  }

  void _init() async {
    AudioPlayer.setIosCategory(IosCategory.playback);

    await _mainPlayer.load(_audioSource);
    await _updateSequence();
    await _fetchMusic();

    print("sequence 1 ===============");
    _sequence(0);

    _location.onLocationChanged.listen((event) {
      _updateLocation(event);
    });

    _mainPlayer.currentIndexStream.listen((event) {
      _sequence(percent);
      _loop();
    });

    _mainPlayer.play();
  }

  Future<void> _updateSequence() async {
    print("_updateSequence");
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
    print("_updateLocation");
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
  }

  void _sequence(int sequencePercent) async {
    print("_sequence: $sequencePercent");
    final int musicIndex = musicData.files.lastIndexWhere(
      (element) => element.breakpoint <= sequencePercent,
    );

    final String stopFile = "https://storage.googleapis.com/futar/" +
        tripData.stops[stopSequence].fileName;

    if (sequencePercent == 0 && announcedStopIndex < stopSequence) {
      announcedStopIndex = stopSequence;

      _emptySource();

      print("seq/0");
      _addToSource("https://storage.googleapis.com/futar/EF-kov.mp3");

      // stop name
      _addToSource(stopFile);

      if (tripData.stops.length - 1 < stopSequence + 1) {
        _addToSource("https://storage.googleapis.com/futar/EF-veg.mp3");
      }

      _addMusic(musicIndex);
    } else if (sequencePercent >= 95 && reachedStopIndex < stopSequence) {
      reachedStopIndex = stopSequence;

      print("seq/1");
      // stop name
      _addToSource(stopFile);
      // music file
      _addToSource(musicData.files.last.pathURL);

      if (tripData.stops.length - 1 >= stopSequence + 1) {
        print("Yea boiiiiiiiiiii");
        await _updateSequence();
        print("seq updated");
        await _fetchMusic();
        print("music fetched");
        _sequence(0);
        print("new seq added");
      } else {
        print("Yea boi");
        _addToSource("https://storage.googleapis.com/futar/EF-veg.mp3");
        _addToSource("https://storage.googleapis.com/futar/EF-visz.mp3");
      }
    } else if (announcedStopIndex != reachedStopIndex) {
      print("seq/2");
      _addMusic(musicIndex);
    } else {
      print("seq/3");
      print(
          "announcedStopIndex: $announcedStopIndex && reachedStopIndex: $reachedStopIndex");
    }
  }

  void _addMusic(int musicIndex) {
    print("_addMusic: $musicIndex");
    final MusicFile music = musicData.files[musicIndex];

    if (musicIndex > 0 && reachedMusicIndex < musicIndex) {
      final MusicFile previousMusic = musicData.files[musicIndex - 1];
      if (!previousMusic.loopable &&
          !_checkIfSourceContains(previousMusic.pathURL)) {
        print("mus/0");
        _addToSource(previousMusic.pathURL);
      }
    }

    if (!_checkIfSourceContains(music.pathURL) ||
        _mainPlayer.currentIndex == _audioSource.children.length - 1) {
      reachedMusicIndex = musicIndex;
      print("mus/1");
      _addToSource(music.pathURL);
    }
  }

  void _loop() {
    print("_loop");
    String currentlyPlaying = _getCurrentUri();
    if (currentlyPlaying == "https://storage.googleapis.com/futar/EF-kov.mp3") {
      updateStop(stopSequence);
      setArtist(musicData.artist);
    } else if (currentlyPlaying ==
        "https://storage.googleapis.com/futar/EF-visz.mp3") {
      dispose(true);
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
    _allUris.add(uri);
    _audioSource.add(
      AudioSource.uri(
        Uri.parse(uri),
      ),
    );
  }

  void _emptySource() {
    print("_emptySource");
    _audioSource.children.removeRange(0, _audioSource.children.length - 1);
  }

  bool _checkIfSourceContains(String uri) {
    print("_checkIfSourceContains: $uri");
    List<String> uris = _audioSource.children
        .map((item) => (item as UriAudioSource).uri.toString())
        .toList();

    return uris.contains(uri);
  }

  String _getCurrentUri() {
    return _allUris[_mainPlayer.currentIndex];
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

  void dispose(bool isGraceful) {
    if (isGraceful && _mainPlayer.playing) {
      Future.delayed(Duration(milliseconds: 250)).then((value) {
        dispose(true);
        return;
      });
    }

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

    endTrip();

    this.tripData = null;
    this.musicData = null;
    this.stopSequence = 0;
    this.updateStop = null;
    this.endTrip = null;
    this.setArtist = null;
    this.reachedMusicIndex = -1;
    this.announcedStopIndex = -1;
    this.reachedStopIndex = -2;
    this.percent = 0;
    this._allUris = List<String>();
  }
}
