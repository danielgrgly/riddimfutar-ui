import 'dart:convert';

class WaveformData {
  int version;
  int channels;
  int sampleRate;
  int sampleSize;
  int bits;
  int length;
  List<int> data;

  WaveformData({
    this.version,
    this.channels,
    this.sampleRate,
    this.sampleSize,
    this.bits,
    this.length,
    this.data,
  });

  factory WaveformData.fromJson(String str) =>
      WaveformData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory WaveformData.fromMap(Map<String, dynamic> json) => new WaveformData(
        version: json["version"] == null ? null : json["version"],
        channels: json["channels"] == null ? null : json["channels"],
        sampleRate: json["sample_rate"] == null ? null : json["sample_rate"],
        sampleSize: json["samples_per_pixel"] == null
            ? null
            : json["samples_per_pixel"],
        bits: json["bits"] == null ? null : json["bits"],
        length: json["length"] == null ? null : json["length"],
        data: json["data"] == null
            ? null
            : new List<int>.from(json["data"].map((x) => x)),
      );

  Map<String, dynamic> toMap() => {
        "version": version == null ? null : version,
        "channels": channels == null ? null : channels,
        "sample_rate": sampleRate == null ? null : sampleRate,
        "samples_per_pixel": sampleSize == null ? null : sampleSize,
        "bits": bits == null ? null : bits,
        "length": length == null ? null : length,
        "data":
            data == null ? null : new List<dynamic>.from(data.map((x) => x)),
      };
}
