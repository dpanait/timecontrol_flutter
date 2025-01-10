import 'package:timecontrol/feature/login/domain/entities/login_rersponse_interface.dart';

class LoginResponseEntity implements ILoginResponse{
  @override
  int administratorsId;

  @override
  String companyName;

  @override
  int idCliente;

  @override
  bool status;

  @override
  String token;

  @override
  String userName;

  @override
  String error;

  LoginResponseEntity({
    required this.status,
    required this.token,
    required this.userName,
    required this.companyName,
    required this.administratorsId,
    required this.idCliente,
    required this.error
    });
  
  @override
  String toString() {
    return 'LoginResponseEntity(status: $status, token: $token, userName: $userName, companyName: $companyName, administratorsId: $administratorsId, idCliente: $idCliente)';
  }
}