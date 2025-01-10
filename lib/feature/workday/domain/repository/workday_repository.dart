import 'package:dartz/dartz.dart';
import 'package:timecontrol/feature/workday/domain/entities/workday_req.dart';
import 'package:timecontrol/feature/workday/domain/entities/workday_request_interface.dart';

abstract class WorkdayRepository{

  Future<Either> getWorkdays(IWorkdayRequest workdayRequest, int itemsPerPage, int currentPage);

  Future<Either> saveDate(IWorkdayRequest workdayRequest, String salEntr);

  Future<Either> getTodayWork();

  Future<Either> initFinPeriod(String initFin);
}