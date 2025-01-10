import 'package:timecontrol/feature/login/domain/entities/login_rersponse_interface.dart';

class LoginResponse implements ILoginResponse{
  late bool status;
  late String token;
  late String userName;
  late String companyName;
  late int administratorsId;
  late int idCliente;
  late String error;

  LoginResponse({
    required this.status,
    required this.token,
    required this.userName,
    required this.companyName,
    required this.administratorsId,
    required this.idCliente,
    required this.error
    });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'token': token,
      'userName': userName,
      'companyName': companyName,
      'administratorsId': administratorsId,
      'idCliente': idCliente,
      'error': error
    };
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? false, // Si no está presente, el valor por defecto es false
      token: json['token'] ?? '',     // Valor por defecto vacío
      userName: json['user_name'] ?? '', // Valor por defecto vacío
      companyName: json['company_name'] ?? '', // Valor por defecto vacío
      administratorsId: json['administrators_id'] ?? 0, // Valor por defecto 0
      idCliente: json['IDCLIENTE'] ?? 0, // Valor por defecto 0
      error: json['error'] ?? ''
    );
  }
}