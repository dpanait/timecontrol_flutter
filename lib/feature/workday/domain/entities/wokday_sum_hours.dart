class SumHours {
  final int hor;
  final int min;
  final int sec;

  SumHours({required this.hor, required this.min, required this.sec});

  factory SumHours.fromJson(Map<String, dynamic> json) {
    return SumHours(
      hor: json['hor'],
      min: json['min'],
      sec: json['sec'],
    );
  }
}