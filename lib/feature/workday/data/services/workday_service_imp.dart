import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:timecontrol/core/constants/config.dart';
import 'package:timecontrol/feature/workday/data/services/workday_service.dart';
import 'package:timecontrol/feature/workday/domain/entities/work_day_status.dart';
import 'package:timecontrol/feature/workday/domain/entities/workday_data.dart';
import 'package:timecontrol/feature/workday/domain/entities/workday_req.dart';
import 'package:timecontrol/feature/workday/domain/entities/workday_request_interface.dart';

class WorkdayServiceImpl implements WorkdayService{

  @override
  Future<Either> getTodayWork() async {
    bool isConnected = await Config.checkInternetConnection();
    if(!isConnected){
      return Left(Exception('No internet connexion'));
    }
    await Config.getVersion();
    try {
      String PostData = jsonEncode({
          'PostData': {
            'action': 'get_work_today_v2',
          }
        });
      // Hacer la solicitud POST usando http
      final response = await http.post(
        Uri.parse(Config.url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer ${Config.token}"
        },
        body: PostData,
      );

      if(kDebugMode){
        log("token: ${Config.token}");
        log("Get work today PostData: $PostData");
        log("Get work today: ${response.body}");
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //print("Start_work_day: $data"); // Aquí puedes hacer algo con la respuesta, como actualizar la UI

        // Mapeo de JSON a la clase WorkDayResponse
        WorkdayDayStatus workdayDayStatus = WorkdayDayStatus.fromJson(data);
        return Right(workdayDayStatus);

      } else {
        return Left(Exception('Failed to load data'));
      }
    } catch (e, stacktrace) {
      print("Error: $e");
      print("Stack Trace: $stacktrace");
      return Left(Exception('Unexpected error: $e - \nStack Trace: $stacktrace'));
    }
  }

  @override
  Future<Either<Exception, WorkdayData>> getWorkdays(IWorkdayRequest workdayRequest, int temsPerPage, int currentPage) async {
    bool isConnected = await Config.checkInternetConnection();
    if(!isConnected){
      return Left(Exception('No internet connexion'));
    }
    try {
      int starIndex = 0;
      if (temsPerPage * currentPage == 0) {
        starIndex = 0;
      } else {
        starIndex = (temsPerPage * (currentPage -1)).ceil();
      }
      
      String url = '${Config.url}?jtPageSize=$temsPerPage&jtStartIndex=$starIndex';
      
      String jsonPost = jsonEncode({
        'PostData': {
          'action': 'list_v2',
          'fecha_start': workdayRequest.dateStart,
          'fecha_fin': workdayRequest.dateEnd
        }
      });
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer ${Config.token}"
        },
        body: jsonPost,
      );
      
      if(kDebugMode){
        print("Url: $url");
        print("_currentPage: $currentPage - pageSize: $starIndex");
        log(jsonPost);
        log(response.body);
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Mapear al modelo WorkdayData
        WorkdayData workdayData = WorkdayData.fromJson(data);

        return Right(workdayData);

      } else {
        return Left(Exception('Failed to load workdays'));
      }
    } catch (e, stacktrace) {
      print("Error: $e");
      print("Stack Trace: $stacktrace");
      
      return Left(Exception('Unexpected error: $e - \nStack Trace: $stacktrace'));
    } finally {
     
    }
  }

  @override
  Future<Either> initFinPeriod(String initFin) async{
    bool isConnected = await Config.checkInternetConnection();
    if(!isConnected){
      return Left(Exception('No internet connexion'));
    }
    final body = jsonEncode({
      "PostData": {
        "action": "save_initfin_v2",
        "period_init_fin": initFin,
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
      
      final data = jsonDecode(response.body);
    
      if(kDebugMode){
        log(Config.url);
        log("initFinPeriod: ${response.body} - ${response.statusCode}");
      }
      if (response.statusCode == 200) {
        return Right(data['status']);
      } else {
        return Left(Exception("Error en la solicitud: ${response.statusCode} - ${data['error']}"));
      }
    } catch (e, stacktrace) {
      print("Error: $e");
      print("Stack Trace: $stacktrace");
      
      return Left(Exception('Unexpected error: $e - \nStack Trace: $stacktrace'));
    }
  }

  @override
  Future<Either> saveDate(IWorkdayRequest workdayRequest, String salEntr) async{
    bool isConnected = await Config.checkInternetConnection();
    if(!isConnected){
      return Left(Exception('No internet connexion'));
    }
    
    //return Left("Error");
   try {
      // Hacer la solicitud POST usando http
      final response = await http.post(
        Uri.parse(Config.url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer ${Config.token}"
        },
        body: jsonEncode({
          'PostData': {
            'action': 'save_entrada_v2',
            'sal_entr': salEntr,
          }
        }),
      );
     
      final data = jsonDecode(response.body);

      if(kDebugMode){
        log(Config.url);
        log("response.statusCode: ${response.statusCode} body: ${response.body}");
      }
      
      if (response.statusCode == 200) {
        
        return Right(data['status']);
      } else {
        return Left(Exception(data['error']));
      }
    } catch (e, stacktrace) {
      print("Error: $e");
      print("Stack Trace: $stacktrace");
      return Left(Exception('Unexpected error: $e - \nStack Trace: $stacktrace'));
    } 
  }
  
}