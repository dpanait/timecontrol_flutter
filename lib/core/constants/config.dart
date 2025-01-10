import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class Config {

  static const domain = "buygest.kuuvoo.com";
  static var version = "pre/dani_d1";
  static var url = "https://${Config.domain}/${Config.version}/yuubbbshop/data_fichar";
  static var environment = "pro";
  static var urlVersion = "https://yuubbb.com/dev/version_avanzado.txt";

  static var userName = "";
  static var companyName = "";
  static var administratorsId = 0;
  static var idCliente = 0;
  static var token = "";
  static var loginCode = "";
  static var code1 = "";
  static var code2 = "";
  static var code3 = "";

  static Future<String> getVersion() async {
    http.Response response;

    try {
      response = await http.get(Uri.parse(Config.urlVersion));
      print("getVersion: ${response.body}");
      print("ENVIROMENT: ${Config.environment}");
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("Version: ${Config.version}");
        }
        if (response.body.contains("PAGINA NO DISPONIBLE")) {
          Fluttertoast.showToast(
              msg: "Error: No podemos identificar la version del sistema. Porfavor contacta con el administrador.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 15,
              backgroundColor: const Color.fromARGB(255, 184, 183, 183),
              textColor: const Color.fromARGB(255, 250, 2, 2),
              fontSize: 16.0);
          return "0";
        } else {
          if (Config.environment == 'pro' && response.body != "Erorr") {
            Config.version = "pro/buy${response.body}";
            Config.url = "https://${Config.domain}/${Config.version}/yuubbbshop/data_fichar";
          }
          return response.body;
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error: ${response.reasonPhrase}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 10, //
            textColor: Colors.white,
            fontSize: 16.0);
        return "0";
      }
    } catch (_) {
      return "Error";
    }
  }

  static Future<bool> checkInternetConnection() async {
    bool isConnected = await InternetConnectionChecker.instance.hasConnection;//await InternetConnectionChecker().hasConnection;
    if(!isConnected){
      showToastNoInternetConnexion();
    }
    return isConnected;
  }
  static showToastNoInternetConnexion(){
     Fluttertoast.showToast(
          msg: "Error: No tienes connexion a internet",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 10, //
          backgroundColor: const Color.fromARGB(255, 184, 183, 183),
          textColor: const Color.fromARGB(255, 250, 2, 2),
          fontSize: 16.0);
  }

}