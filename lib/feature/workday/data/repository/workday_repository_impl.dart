import 'package:dartz/dartz.dart';
import 'package:timecontrol/feature/workday/data/services/workday_service.dart';
import 'package:timecontrol/feature/workday/domain/entities/workday_request_interface.dart';
import 'package:timecontrol/feature/workday/domain/repository/workday_repository.dart';
import 'package:timecontrol/service_locator.dart';

class WorkdayRepositoryImpl implements WorkdayRepository{
  @override
  Future<Either> getWorkdays(IWorkdayRequest workdayRequest, int itemsPerPage, int currentPage) {
    return sl<WorkdayService>().getWorkdays(workdayRequest, itemsPerPage, currentPage);
  }
  
  @override
  Future<Either> getTodayWork() {
    return sl<WorkdayService>().getTodayWork();
  }
  
  @override
  Future<Either> initFinPeriod(String initFin) {
    return sl<WorkdayService>().initFinPeriod(initFin);
  }
  
  @override
  Future<Either> saveDate(IWorkdayRequest workdayRequest, String salEntr) {
   return sl<WorkdayService>().saveDate(workdayRequest, salEntr);
  }
  
}
