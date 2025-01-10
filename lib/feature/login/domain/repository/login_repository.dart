import 'package:dartz/dartz.dart';
import 'package:timecontrol/feature/login/domain/entities/login_entity.dart';

abstract class LoginRepository {

  Future<Either> login(LoginEntity loginEntity);
  Future<Either> logout();
}