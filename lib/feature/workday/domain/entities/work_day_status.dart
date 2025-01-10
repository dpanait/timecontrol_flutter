import 'package:timecontrol/feature/workday/domain/entities/work_day_record.dart';

class WorkdayDayStatus {
  bool status;
  int startWorkDay;
  List<WorkDayRecord> records;

  WorkdayDayStatus({
    required this.status,
    required this.startWorkDay,
    required this.records,
  });

  // Método para convertir JSON a objeto de tipo WorkdayResponse
  factory WorkdayDayStatus.fromJson(Map<String, dynamic> json) {
    return WorkdayDayStatus(
      status: json['status'],
      startWorkDay: int.parse(json['start_work_day'].toString()) ?? 0,
      records: (json['records'] as List)
          .map((record) => WorkDayRecord.fromJson(record))
          .toList(),
    );
  }

  // Método para convertir objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'start_work_day': startWorkDay,
      'records': records.map((record) => record.toJson()).toList(),
    };
  }
}