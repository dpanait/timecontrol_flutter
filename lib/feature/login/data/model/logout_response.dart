import 'package:timecontrol/feature/login/domain/entities/logout_response_interface.dart';

class LogoutResponse implements ILogoutResponse{
  @override
  late String error;

  @override
  late bool status;

  LogoutResponse({required this.status, required this.error});

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'error': error
    };
  }

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      status: json['status'] ?? false,
      error: json['error'] ?? ''
    );
  }
}