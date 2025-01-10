import 'package:timecontrol/feature/login/domain/entities/login_interface.dart';

class LoginEntity implements ILogin{
  late String code1;
  late String code2;
  late String code3;

  LoginEntity({required this.code1, required this.code2, required this.code3});
}