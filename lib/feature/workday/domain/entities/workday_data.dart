import 'package:timecontrol/feature/workday/domain/entities/workday.dart';

class WorkdayData {
  final int total;
  final List<Workday> datas;

  WorkdayData({required this.total, required this.datas});

  factory WorkdayData.fromJson(Map<String, dynamic> json) {
    return WorkdayData(
      total: int.parse(json['total']),
      datas: (json['datas'] as List).map((item) => Workday.fromJson(item)).toList(),
    );
  }

  static WorkdayData empty() {
    return WorkdayData(
      total: 0,
      datas: []
    );
  }
}
