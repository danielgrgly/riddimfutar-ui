import "./WaveformData.dart";

class MusicFile {
  String pathURL;
  int breakpoint;
  bool loopable;
  bool announceUnder;
  WaveformData waveform;

  MusicFile({
    this.pathURL,
    this.breakpoint,
    this.loopable,
    this.announceUnder,
    this.waveform,
  });

  factory MusicFile.fromJson(Map<String, dynamic> json) {
    return MusicFile(
      pathURL: json["pathURL"],
      breakpoint: json["breakpoint"],
      loopable: json["loopable"],
      announceUnder: json["announceUnder"],
      waveform: WaveformData.fromMap(
        json["waveform"],
      ),
    );
  }
}

class MusicDetails {
  String artist;
  String title;
  List<MusicFile> files;

  MusicDetails({
    this.artist,
    this.title,
    this.files,
  });

  factory MusicDetails.fromJson(Map<String, dynamic> json) {
    return MusicDetails(
      artist: json['artist'],
      title: json['title'],
      files:
          json['files'].map<MusicFile>((i) => MusicFile.fromJson(i)).toList(),
    );
  }
}
