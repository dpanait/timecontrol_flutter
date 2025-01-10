import 'package:dartz/dartz.dart';
import 'package:timecontrol/feature/login/data/services/login_service.dart';
import 'package:timecontrol/feature/login/domain/entities/login_interface.dart';
import 'package:timecontrol/feature/login/domain/repository/login_repository.dart';
import 'package:timecontrol/service_locator.dart';

class LoginRepositoryImpl implements LoginRepository{
  @override
  Future<Either> login(ILogin loginModel) async{

    final result = await sl<LoginService>().login(loginModel);

    return result.fold(
        (exception) {
          return Left(Exception( exception.toString()));
        },
        (loginResponse) {
          return Right(loginResponse);
        },
      );
    //return Left(Exception("Problemas con la conexion"));
  }
  
  @override
  Future<Either> logout() {
    return sl<LoginService>().logout();
  }
}