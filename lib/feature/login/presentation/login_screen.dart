import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timecontrol/core/constants/config.dart';
import 'package:timecontrol/feature/login/data/model/login_response.dart';
import 'package:timecontrol/feature/login/domain/entities/login_entity.dart';
import 'package:timecontrol/feature/login/domain/entities/login_resposne_entitiy.dart';
import 'package:timecontrol/feature/login/domain/repository/login_repository.dart';
import 'package:timecontrol/service_locator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _usernameController = TextEditingController();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  String result = "Escanee un código QR";
  String _errorMessage = "";
  // Controlador para el escáner
  MobileScannerController cameraController = MobileScannerController();
  bool _isScannerActive = false; // Controla si el escáner está activo

  @override
  void initState() {
    super.initState();
    checkCameraPermission();
    cameraController = MobileScannerController(
      detectionTimeoutMs: 100, // Ajusta este valor si es necesario
    );
  
    checkLogin();
  }

  @override
  void reassemble() {
    super.reassemble();
    checkLogin();
    // if (controller != null) {
    //   // controller!.pauseCamera();
    //   // controller!.resumeCamera();
    // }
  }
  
   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if(mounted){
       checkLogin();
    }
  }
  @override
  void dispose() {
    // controller?.dispose();
    _usernameController.text = "";
    cameraController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
  Future<void> checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  void _toggleScanner() {
    setState(() {
      _isScannerActive = !_isScannerActive; // Activa o desactiva el escáner
      if (!_isScannerActive) {
        cameraController.stop(); // Detiene el escáner cuando está inactivo
      }
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      setState(() {
        _usernameController.text = capture.barcodes.first.rawValue ?? "";
        result = capture.barcodes.first.rawValue ?? "Código no válido";
      });
      // Opcional: Detener el escáner automáticamente después de un escaneo exitoso
      _toggleScanner();
    }
  }
  void checkLogin() async{
    final token = await getSession();
    if(kDebugMode){
      log(token.toString());
    }
    if(token != null && token.isNotEmpty){
      //_showLoadingDialog(context, token);
      LoginResponse loginResponse = await getUserData();
      String loginCodeParam = (await secureStorage.read(key: 'login_code'))!;
      populateConfigUserData(loginResponse, loginCodeParam);
      // Navegar a la pantalla Workday
      Navigator.pushNamed(context, '/workday');

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Codígos para login",
                  prefixIcon: IconButton(
                      onPressed: () {
                       _toggleScanner();
                      },
                      icon: Icon(Icons.document_scanner_rounded)
                  ),
                  suffixIcon: IconButton(
                      onPressed: (){
                        _usernameController.text = "";
                      },
                      icon: Icon(Icons.close)
                  )
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor, introduce tu usuario";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async{
                  if(mounted){
                    checkLogin();
                  }

                  if (_formKey.currentState?.validate() ?? false) {
                    List<String> loginCode = _usernameController.text.toUpperCase().split(",");

                    LoginEntity loginEntity = LoginEntity(code1: loginCode[0], code2: loginCode[1], code3: loginCode[2]);
                
                    final resultLogin = await sl<LoginRepository>().login(loginEntity);
                    //log("resultLogin: $resultLogin");
                    resultLogin.fold(
                      (exception) {
                        log(exception.toString());
                        _showLoadingDialog(context, exception.toString());
                      },
                      (loginResponse) {
                        debugPrint("loginResponse: ${loginResponse}");

                        if(loginResponse.status){
              
                          saveUserData(loginResponse,  _usernameController.text);
                          populateConfigUserData(loginResponse, _usernameController.text);

                          // Navegar a la pantalla Workday
                          Navigator.pushNamed(context, '/workday');

                        }

                      },
                    );
                    

                  }
                },
                child: Text("Login"),
              ),
              SizedBox(height: 20),

              if (_isScannerActive) // Mostrar escáner solo si está activo
                Container(
                  height: 300,
                  child: MobileScanner(
                    controller: cameraController,
                    onDetect: _onDetect,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  // Función para mostrar un loading dialog
  void _showLoadingDialog(BuildContext context, [String message = "Cargando..."]) {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera del dialog
      builder: (context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }
  Future<void> saveSession(String token) async {
    await secureStorage.write(key: 'auth_token', value: token);
  }
  Future<String?> getSession() async {
    return await secureStorage.read(key: 'auth_token');
  }
  Future<void> clearSession() async {
    await secureStorage.delete(key: 'auth_token');
  }
  Future<void> saveUserData(LoginResponse loginResponse, String loginCode) async {
    await secureStorage.write(key: 'auth_token', value: loginResponse.token);
    await secureStorage.write(key: 'login_code', value: loginCode);
    await secureStorage.write(key: 'administrators_id', value: loginResponse.administratorsId.toString());
    await secureStorage.write(key: 'user_name', value: loginResponse.userName);
    await secureStorage.write(key: 'company_name', value: loginResponse.companyName);
    await secureStorage.write(key: 'IDCLIENTE', value: loginResponse.idCliente.toString());
  }
  Future<LoginResponse> getUserData() async{
    return await LoginResponse(
      status: true, 
      token: (await secureStorage.read(key: 'auth_token'))!, 
      userName: (await secureStorage.read(key: 'user_name'))!, 
      companyName: (await secureStorage.read(key: 'company_name'))!, 
      administratorsId: int.parse((await secureStorage.read(key: 'administrators_id'))!), 
      idCliente: int.parse((await secureStorage.read(key: 'IDCLIENTE'))!),
      error: '');
  }
  
  Future<void> populateConfigUserData(LoginResponse loginResponse, String loginCodeParam) async{

    String loginCode = loginCodeParam;
    Config.userName = loginResponse.userName;
    Config.companyName = loginResponse.companyName;
    Config.administratorsId = loginResponse.administratorsId;
    Config.idCliente = loginResponse.idCliente;
    Config.token = loginResponse.token;
    Config.loginCode = loginCode;
    Config.code1 = loginCode.split(",")[0];
    Config.code2 = loginCode.split(",")[1];
    Config.code3 = loginCode.split(",")[2];

  }
  Future<void> clearUserData() async{
    await secureStorage.delete(key: 'auth_token');
    await secureStorage.delete(key: 'login_code');
    await secureStorage.delete(key: 'administrators_id');
    await secureStorage.delete(key: 'user_name');
    await secureStorage.delete(key: 'company_name');
    await secureStorage.delete(key: 'IDCLIENTE');
  }

}
