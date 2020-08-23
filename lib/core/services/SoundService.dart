import 'dart:convert';
import 'dart:async';
import 'dart:core';

import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:riddimfutar/core/models/WaveformData.dart';

import "../../core/utils.dart";
import "../../core/models/MusicDetails.dart";
import "../../core/models/TripDetails.dart";

final _mainPlayer = AudioPlayer();

ConcatenatingAudioSource audioSource = ConcatenatingAudioSource(
  children: [
    AudioSource.uri(
      Uri.parse("https://storage.googleapis.com/futar/EF-udv.mp3"),
    ),
  ],
);

final Location _location = Location();

class SoundService {
  TripDetails tripData;
  MusicDetails musicData;
  String tripId;
  int sequence;
  Function updateStop;
  Function endTrip;
  Function setArtist;
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
    this.updateStop = updateStop;
    this.endTrip = endTrip;
    this.setArtist = setArtist;
    this.reachedIndex = -1;

    AudioPlayer.setIosCategory(IosCategory.playback);

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
    await _mainPlayer.load(audioSource);

    _mainPlayer.play();

    await _fetchMusic();
    updateStop(sequence);
    setArtist(musicData.artist);
    _reachBreakpoint(0);
    _listenSounds();
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
    } else {
      _addToSource(_getCurrentUri());
    }
  }

  void _reachBreakpoint(int percent) async {
    final int musicIndex = musicData.files.lastIndexWhere(
      (element) => element.breakpoint <= percent,
    );

    final String stopFile = "https://storage.googleapis.com/futar/" +
        tripData.stops[sequence].fileName;

    if (percent == 0) {
      _addToSource("https://storage.googleapis.com/futar/EF-kov.mp3");

      // stop name
      _addToSource(stopFile);

      if (tripData.stops.length - 1 < sequence + 1) {
        _addToSource("https://storage.googleapis.com/futar/EF-veg.mp3");
      }

      _addMusic(musicIndex);
    } else if (percent >= 95) {
      // stop name
      _addToSource(stopFile);
      // music file
      _addToSource(this.musicData.files.last.pathURL);

      if (tripData.stops.length - 1 >= sequence + 1) {
        print("yea i should come");
        sequence += 1;
        await _fetchMusic();
        _reachBreakpoint(0);
      } else {
        _addToSource("https://storage.googleapis.com/futar/EF-veg.mp3");
        _addToSource("https://storage.googleapis.com/futar/EF-visz.mp3");
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
          !_checkIfSourceContains(previousMusic.pathURL)) {
        _addToSource(previousMusic.pathURL);
      }
    }

    if (!_checkIfSourceContains(music.pathURL)) {
      _addToSource(music.pathURL);
    }
  }

  void _listenSounds() {
    if (_getCurrentUri() == "https://storage.googleapis.com/futar/EF-kov.mp3") {
      updateStop(sequence);
      setArtist(musicData.artist);
    }

    if (_getCurrentUri() ==
        "https://storage.googleapis.com/futar/EF-visz.mp3") {
      audioSource.children.removeRange(0, audioSource.children.length - 1);

      endTrip();
    }
  }

  Future<dynamic> _fetchMusic() async {
    final String genre = tripData.stops[sequence].musicOverride ?? "riddim";
    final response = await http.get(
      'https://riddimfutar.ey.r.appspot.com/api/v1/music/$genre',
    );

    if (response.statusCode == 200) {
      reachedIndex = -1;
      this.musicData = MusicDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch music');
    }
  }

  void _addToSource(String uri) {
    audioSource.add(
      AudioSource.uri(
        Uri.parse(uri),
      ),
    );
  }

  bool _checkIfSourceContains(String uri) {
    return audioSource.children.contains(
      AudioSource.uri(
        Uri.parse(uri),
      ),
    );
  }

  String _getCurrentUri() {
    return (audioSource.children[_mainPlayer.currentIndex] as UriAudioSource)
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

  void destroy() {
    _mainPlayer.stop();

    this.tripId = null;
    this.tripData = null;
    this.sequence = 0;
    this.updateStop = null;
    this.endTrip = null;
  }
}
