import 'package:timecontrol/feature/workday/domain/entities/workday_request_interface.dart';

class WorkdayRequest implements IWorkdayRequest{
  late String code1;
  late String code2;
  late String code3;
  late String dateStart;
  late String dateEnd;

  WorkdayRequest({required this.code1, required this.code2, required this.code3, required this.dateStart, required this.dateEnd});
}