class MusicFile {
  int breakpoint;
  String fileName;
  bool loopable;
  bool announceUnder;

  MusicFile({
    this.breakpoint,
    this.fileName,
    this.loopable,
    this.announceUnder,
  });

  factory MusicFile.fromJson(Map<String, dynamic> json) {
    return MusicFile(
        breakpoint: json['breakpoint'],
        fileName: json['name'],
        loopable: json['loopable'],
        announceUnder: json['announceUnder']);
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
      artist: json['config']['artist'],
      title: json["config"]['title'],
      files: json["config"]['files']
          .map<MusicFile>((i) => MusicFile.fromJson(i))
          .toList(),
    );
  }
}
