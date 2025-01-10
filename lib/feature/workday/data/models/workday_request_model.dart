import 'package:timecontrol/feature/workday/domain/entities/workday_request_interface.dart';

class WorkdayRequestModel implements IWorkdayRequest{
  @override
  late String code1;

  @override
  late String code2;

  @override
  late String code3;

  @override
  String dateEnd;

  @override
  late String dateStart;

  WorkdayRequestModel({
    required this.code1,
    required this.code2,
    required this.code3,
    required this.dateEnd,
    required this.dateStart
  });
  
}

