import 'package:get_it/get_it.dart';
import 'package:timecontrol/feature/login/data/repository/login_repository_impl.dart';
import 'package:timecontrol/feature/login/data/services/login_service.dart';
import 'package:timecontrol/feature/login/domain/repository/login_repository.dart';
import 'package:timecontrol/feature/workday/data/repository/workday_repository_impl.dart';
import 'package:timecontrol/feature/workday/data/services/workday_service.dart';
import 'package:timecontrol/feature/workday/data/services/workday_service_imp.dart';
import 'package:timecontrol/feature/workday/domain/repository/workday_repository.dart';

final sl = GetIt.instance;

void setupServiceLocator(){
  //Repositorios
  sl.registerSingleton<WorkdayRepository>(WorkdayRepositoryImpl());
  sl.registerSingleton<LoginRepository>(LoginRepositoryImpl());

  // services
  sl.registerSingleton<WorkdayService>(WorkdayServiceImpl());
  sl.registerSingleton<LoginService>(LoginServiceImpl());
}