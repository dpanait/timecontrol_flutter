import 'package:timecontrol/feature/workday/domain/entities/work_day_record.dart';

class WorkdayDayStatus {
  bool status;
  int? startWorkDay;
  List<WorkDayRecord> records;
  String error;

  WorkdayDayStatus({
    required this.status,
    required this.startWorkDay,
    required this.records,
    required this.error
  });

  // Método para convertir JSON a objeto de tipo WorkdayResponse
  factory WorkdayDayStatus.fromJson(Map<String, dynamic> json) {
    return WorkdayDayStatus(
      status: json.containsKey('status') ? json['status'] ?? false : false,
      startWorkDay: json.containsKey('start_work_day') && json['start_work_day'] != null
          ? int.tryParse(json['start_work_day'].toString()) ?? 0
          : 0,
      records: json.containsKey('records') && json['records'] != null
          ? (json['records'] as List)
              .map((record) => WorkDayRecord.fromJson(record))
              .toList()
          : [],
      error: json.containsKey('error') && json['error'] != null ? json['error'] : '',
    );
  }

  // Método para convertir objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'start_work_day': startWorkDay,
      'records': records.map((record) => record.toJson()).toList(),
      'error': error
    };
  }
}