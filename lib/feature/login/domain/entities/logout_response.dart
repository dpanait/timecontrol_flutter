import 'package:timecontrol/feature/login/domain/entities/logout_response_interface.dart';

class LoginResponse implements ILogoutResponse{
  @override
  late String error;

  @override
  late bool status;
  
}