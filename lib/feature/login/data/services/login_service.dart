import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:timecontrol/core/constants/config.dart';
//import 'package:timecontrol/feature/login/data/model/login_model.dart';
import 'package:timecontrol/feature/login/data/model/login_response.dart';
import 'package:timecontrol/feature/login/data/model/logout_response.dart';
import 'package:timecontrol/feature/login/domain/entities/login_interface.dart';

abstract class LoginService{
  Future<Either> login(ILogin loginModel);
  Future<Either> logout();
}

class LoginServiceImpl implements LoginService{
  @override
  Future<Either> login(ILogin loginModel) async{
    bool isConnected = await Config.checkInternetConnection();
    if(!isConnected){
      return Left(Exception('No internet connexion'));
    }
    await Config.getVersion();
    
    final body = jsonEncode({
      "PostData": {
        "action": "check_login_code",
        "login_code": "${loginModel.code1},${loginModel.code2},${loginModel.code3}",
      }
    });

    try {
      // Realiza la solicitud POST
      final response = await http.post(
        Uri.parse(Config.url),
        headers: {
          "Content-Type": "application/json"
        },
        body: body,
      );

      if(kDebugMode){
         log(response.body);
      }
     
      // Parsear la respuesta
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Right(LoginResponse.fromJson(data));
      } else {
        return Left(Exception("Error en la solicitud: ${response.statusCode} - ${LoginResponse.fromJson(data).error}"));
      }
    } catch (e, stacktrace) {
      print("Error: $e");
      print("Stack Trace: $stacktrace");
      
      return Left(Exception('Unexpected error: $e - \nStack Trace: $stacktrace'));
    }
  }

  Future<Either> logout() async{
    bool isConnected = await Config.checkInternetConnection();
    if(!isConnected){
      return Left(Exception('No internet connexion'));
    }
    await Config.getVersion();
    
    final body = jsonEncode({
      "PostData": {
        "action": "logout_v2",
      }
    });

    try {
      // Realiza la solicitud POST
      final response = await http.post(
        Uri.parse(Config.url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': "Bearer ${Config.token}"
        },
        body: body,
      );
      
      if(kDebugMode){
        log(response.body);
      }

      // Parsear la respuesta
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Right(LogoutResponse.fromJson(data));
      } else {
        return Left(Exception("Error en la solicitud: ${response.statusCode} - ${LoginResponse.fromJson(data).error}"));
      }
    } catch (e, stacktrace) {
      print("Error: $e");
      print("Stack Trace: $stacktrace");
      
      return Left(Exception('Unexpected error: $e - \nStack Trace: $stacktrace'));
    }

  }
  
}