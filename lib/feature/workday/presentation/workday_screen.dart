import 'dart:async';

import 'dart:convert';
import 'dart:math' as Math;
import 'dart:developer';

//import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timecontrol/core/constants/config.dart';
import 'package:timecontrol/feature/login/domain/repository/login_repository.dart';
import 'package:timecontrol/feature/workday/domain/entities/work_day_record.dart';
import 'package:timecontrol/feature/workday/domain/entities/work_day_status.dart';
import 'package:timecontrol/feature/workday/domain/entities/workday.dart';
import 'package:timecontrol/feature/workday/domain/entities/workday_req.dart';
import 'package:timecontrol/feature/workday/domain/repository/workday_repository.dart';
import 'package:timecontrol/service_locator.dart';

class WorkdayScreen extends StatefulWidget {
  @override
  _WorkdayScreenState createState() => _WorkdayScreenState();
}

class _WorkdayScreenState extends State<WorkdayScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late WorkdayDayStatus _workdayDayStatus;

  Stopwatch _stopwatch = Stopwatch();
  Duration _initialElapsedTime = Duration.zero; // Tiempo inicial desde el servidor
  late String _timeElapsed = '00:00:00';
  late Timer? _timer = Timer(Duration.zero, () {});
  bool _isWorkdayStarted = false; // Estado para gestionar la jornada laboral
  bool _isRunning = false; // Estado para alternar entre Start/Stop
  bool _isApiCallInProgress = false;

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  Color darkGrey = Colors.grey[900]!;

  // Variables para el grid
  final int _itemsPerPage = 32; // Cantidad de items por página
  int _currentPage = 1; // Página actual
  bool _isLoading = false; // Estado de carga
  List<Workday> _workdays = []; // Datos de las jornadas laborales
  int _totalPages = 1;

  // Fechas predeterminadas
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1); // Primer día del mes actual
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(Duration(days: 1)); // Último día del mes actual

  @override
  void initState() {
    super.initState();
    _timeElapsed = _formatDuration(Duration.zero);
    if(mounted){
      _getWorkday();
    }
  }

  @override
  void dispose() {
    _timer!.cancel();
    super.dispose();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ahora puedes acceder al contexto de forma segura
    final theme = Theme.of(context); // No genera error
    if(mounted){
    _getTodayWork();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _startWorkday() {
    setState(() {
      _isWorkdayStarted = true;
      _isRunning = true;
      _isApiCallInProgress = true;
    });
    _startTimer();
    //saveDate("entrada", urlApi);
    _saveData("entrada");
   
  }

 void _startTimer() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          // Calcula el tiempo total transcurrido
          _timeElapsed = _formatDuration(
            _initialElapsedTime + _stopwatch.elapsed,
          );
        });
      });
    }
  }


  void _stopTimer() {
    _stopwatch.stop();
    _timer!.cancel();
  }

  void _toggleStartStop() {
    if (_isRunning) {
      _stopTimer();
      _initFinPeriodo("stop");
      setState(() {
        //_isApiCallInProgress = false;
      });
    } else {
      _startTimer();
      _initFinPeriodo("start");
      setState(() {
        //_isApiCallInProgress = false;
      });
    }
    setState(() {
      _isRunning = !_isRunning;
      _isApiCallInProgress = true;
    });
  }

  void _endWorkday() {
    _stopTimer();
    _stopwatch.reset();
    //saveDate("salida", urlApi);
    _saveData("salida");
    setState(() {
      _timeElapsed = _formatDuration(Duration.zero);
      _isWorkdayStarted = false;
      _isRunning = false;
      _isApiCallInProgress = true;
    });
    
  }

  void _goToPage(int page) {
    //print("page: $page - $_currentPage - $_totalPages");
    if (page >= 0 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _getWorkday();
    }
  }
  
  
  @override
  Widget build(BuildContext context) {
    //print("_isRunning: $_isRunning - _isWorkdayStarted: $_isWorkdayStarted");
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 73, 73, 75),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.asset('assets/logo/logokuuvooblanco.svg',
                fit: BoxFit.cover,
                width: 40,
                height: 20
              ),
              Text("${Config.companyName}", style: TextStyle(color: Colors.white)),
            ],
          ),
          actions:[
            IconButton(onPressed: () async{
              await clearUserData();
              await sl<LoginRepository>().logout();

              Navigator.pop(context);//pushNamed(context, '/workday');
            },
            icon: Icon(Icons.logout, color: Colors.white))
          ]
      ),
      body: Stack(
        children: [
          Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _userName(),
              _timerView(),
              SizedBox(height: 20),
              _clockAnButtons(),
              Row(
                children: [
                  _dataPicker(),
                  _searchBtn(),
                ],
              ),
              Divider(),
              // Grid de jornadas laborales
              Expanded(
                child: Column(
                  children: [
                    if (_isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _workdays.length,
                          itemBuilder: (context, index) {
        
                            final workday = _workdays[index];
                            String totalWorkTime = workday.tiempoTrabajado ?? "";
        
                            if(workday.administratorsId == 0){
                              Map<String, int> workTime = sumHoras(workday.sumHours!.hor, workday.sumHours!.min, workday.sumHours!.sec);
                              totalWorkTime = "${checkDecimal(workTime['hor']!)} : ${checkDecimal(workTime['min']!)} : ${checkDecimal(workTime['sec']!)}";
                            }
                            
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _user(Config.userName),
                                    _day(workday.dia!),
                                    _hoursRange(workday.horas!),
                                    _totalHours(totalWorkTime),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    // Paginación
                    Padding(
                      padding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Botón "Atrás"
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios),
                                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                              ),
                              
                              // Rango de páginas visibles
                              ..._getPageRange().map((page) {
                                return page == -1
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                                        child: Text("..."),
                                      )
                                    : _buildPageButton(page);
                              }).toList(),
        
                              // Botón "Adelante"
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                              ),
                            ],
                          ),
                        ]
                        
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isApiCallInProgress) // Overlay transparente
          Container(
            margin:EdgeInsets.only(top: 80),
            height: 110,
            color: Colors.black.withOpacity(0.5), // Transparencia
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ]
      ),
    );
  }
  Widget _userName(){
    return  Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Usuario: ${Config.userName}")
    ],);
  }
  RichText _hoursRange(String rangoHoras){

    if(rangoHoras.contains("Pendiente salida")){

      // Eliminar las etiquetas HTML usando RegExp
      String cleanText = rangoHoras.replaceAll(RegExp(r'<[^>]*>'), '');
      List<String> completeDate = cleanText.split(",");
      List<TextSpan> textSpanList =[];
      textSpanList.add(
        TextSpan(
          text: "Rango de horas: \n", // Título en texto normal
          style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey,)
        )
      );
      completeDate.forEach((element) {
        
        if(element.contains("Pendiente salida")){
          // Separar la fecha y el texto para poder estilizar "Pendiente salida"
          List<String> parts = element.split(' - ');

          //allData.add(parts);

            parts.forEach((item){

              if(item.contains("Pendiente salida")){
                  textSpanList.add(
                TextSpan(
                    text: "$item \n", // Mostrar la fecha
                    style: const TextStyle(color: Colors.red), // Color para la fecha
                  ),
                );

              } else {

              textSpanList.add(
                TextSpan(
                    text: '$item - ', // Mostrar la fecha
                    style: const TextStyle(color: Colors.black), // Color para la fecha
                  ),
                );
               }
            });  

        } else {

          textSpanList.add(
            TextSpan(
                text: "${element.replaceAll(",", "\n")}\n", // Mostrar la fecha
                style: const TextStyle(color: Colors.black), // Color para la fecha
              ),
            );
        }
        
      });

      return RichText(
        text: TextSpan(
          children: textSpanList   
        )
        
      );
    } else {
      return RichText(
        text: TextSpan(
          text: "Rango de horas: \n", // Título en texto normal
          style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey,), // Título en negrita
          children: <TextSpan>[
            TextSpan(
              text: rangoHoras.replaceAll(",", "\n"), // El valor no va en negrita
              style: TextStyle(fontWeight: FontWeight.normal, color: darkGrey,), // Estilo normal
            ),
          ],
        ),
      );
    }
    
  }
  RichText _user(String user){
    return RichText(
      text: TextSpan(
        text: "Usuario: ", // Título en texto normal
        style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey,), // Título en negrita
        children: <TextSpan>[
          TextSpan(
            text: "$user", // El valor no va en negrita
            style: TextStyle(fontWeight: FontWeight.normal, color: darkGrey,), // Estilo normal
          ),
        ],
      ),
    );
  }
  RichText _day(String day){
    return RichText(
      text: TextSpan(
        text: "Día: ", // Título en texto normal
        style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey,), // Título en negrita
        children: <TextSpan>[
          TextSpan(
            text: day, // El valor no va en negrita
            style: TextStyle(fontWeight: FontWeight.normal, color: darkGrey,), // Estilo normal
          ),
        ],
      ),
    );
  }
  RichText _totalHours(String hours){
    return RichText(
      text: TextSpan(
        text: "Total horas: ", // Título en texto normal
        style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey,), // Título en negrita
        children: <TextSpan>[
          TextSpan(
            text: hours, // El valor no va en negrita
            style: TextStyle(fontWeight: FontWeight.normal, color: darkGrey,), // Estilo normal
          ),
        ],
      ),
    );
  }
  Widget _buildPageButton(int page) {
    return ElevatedButton(
      onPressed: () => _goToPage(page),
      style: ElevatedButton.styleFrom(
        backgroundColor: page == _currentPage
            ? Colors.blue
            : Colors.grey[300],
        foregroundColor:
            page == _currentPage ? Colors.white : Colors.black,
        fixedSize: Size(20, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Sin bordes redondeados
        )
      ),
      child: Text(
        page.toString(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _currentPage == page ? Colors.white : const Color.fromARGB(255, 39, 39, 39),
        ),
        softWrap: false,
      ),
    );
  }

  List<int> _getPageRange() {
    const int maxVisibleButtons = 3; // Número máximo de botones visibles
    List<int> range = [];

    if (_totalPages <= maxVisibleButtons) {
      // Si el total de páginas es menor que el máximo, muestra todas las páginas
      range = List.generate(_totalPages, (index) => index + 1);
    } else {
      // Si hay muchas páginas, muestra un rango dinámico
      int start = (_currentPage - 2).clamp(1, _totalPages - maxVisibleButtons + 1);
      int end = (start + maxVisibleButtons - 1).clamp(1, _totalPages);

      range = List.generate(end - start + 1, (index) => start + index);

      // Añade "..." para indicar más páginas
      if (start > 1) range.insert(0, -1); // -1 representa "..."
      if (end < _totalPages) range.add(-1);
    }

    return range;
  }

  Map<String, int> sumHoras(int hor, int min, int sec) {
    if (sec > 59) {
      min += (sec / 60).floor();
      sec = sec % 60;
    }

    if (min > 59) {
      hor += (min / 60).floor();
      min = min % 60;
    }

    return {'hor': hor, 'min': min, 'sec': sec};
  }
  String checkDecimal(int elem) {
    return elem < 10 ? '0$elem' : elem.toString();
  }
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020), // Fecha mínima
      lastDate: DateTime(2100), // Fecha máxima
      helpText: "Selecciona un período", // Texto del encabezado
      confirmText: "Confirmar", // Texto del botón de confirmación
      cancelText: "Cancelar", // Texto del botón de cancelar
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Puedes realizar una llamada al servidor con las fechas seleccionadas
      _fetchDataFromServer(_startDate, _endDate);
    }
  }
  void _fetchDataFromServer(DateTime startDate, DateTime endDate) {
    // Simula una llamada al servidor con las fechas seleccionadas
    print("Fetching data from: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}");
  }

  Widget _dataPicker(){
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectDateRange(context),
              child: Text("${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}"),
            ),
          ],
        ),
      ),
    );
  }
  Widget _searchBtn(){
    return ElevatedButton(
      onPressed: () => _getWorkday(),
      style: ElevatedButton.styleFrom(
        backgroundColor:  Colors.blue,
        foregroundColor: Colors.white ,
        //fixedSize: Size(0, 30),
      ),
      child: Text("Buscar"),
    );
  }
  Widget _timerView(){
    return Container(
      color: Colors.black,
      width: 160,
      height: 45,
      child: Center(
        child: Text(
          _timeElapsed,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            backgroundColor: Colors.black
          ),
        ),
      ),
    );

  }
  Widget _clockAnButtons(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isWorkdayStarted ? null : _startWorkday,
          child: const Icon(Icons.timer, size: 40),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _isWorkdayStarted ? _toggleStartStop : null,
          child: _isRunning ? const Icon(Icons.pause_circle, size: 40) : const Icon(Icons.play_circle, size: 40),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _isWorkdayStarted ? _endWorkday : null,
          child: const Icon(Icons.timer_off, size: 40),
        ),
      ],
    );
  }
 
  Future<void> _getWorkday() async {

    setState(() {
      _isLoading = true;
    });
    
    WorkdayRequest request = WorkdayRequest(
      code1: Config.code1,
      code2: Config.code2,
      code3: Config.code3,
      dateStart: DateFormat('yyyy-MM-dd').format(_startDate),
      dateEnd: DateFormat('yyyy-MM-dd').format(_endDate),
    );
    //log("request: $request");
    try{
      final result = await sl<WorkdayRepository>().getWorkdays(request, _itemsPerPage, _currentPage);
      result.fold(
        (exception) {
          _showLoadingDialog(context, exception.toString());
        },
        (workdayData) {
          if(mounted){
            setState(() {
              _workdays = workdayData.datas;
              _totalPages = (workdayData.total / _itemsPerPage).ceil();
              _isApiCallInProgress = false;
            });
          }
         
        },
      );
      
    } catch(e, stacktrace){     
      print("Error: $e");
      print("Stack Trace: $stacktrace");
    } finally {
      setState(() {
        _isLoading = false;
        _isApiCallInProgress = false;
      });
    }

  }
  Future<void> _initFinPeriodo(String initFin) async {
    
    try{
      final result = await sl<WorkdayRepository>().initFinPeriod(initFin);
      //log("result: $result");
      result.fold(
        (exception) {
          _showLoadingDialog(context, exception.toString());
        },
        (status) {
          if(status == true){
            
            _getWorkday();

          }
          
        },
      );
      
    } catch(e, stacktrace){     
      print("Error: $e");
      print("Stack Trace: $stacktrace");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _saveData( String salEntr) async{

   WorkdayRequest request = WorkdayRequest(
      code1: Config.code1,
      code2: Config.code2,
      code3: Config.code3,
      dateStart: DateFormat('yyyy-MM-dd').format(_startDate),
      dateEnd: DateFormat('yyyy-MM-dd').format(_endDate),
    );
    try{
      final result = await sl<WorkdayRepository>().saveDate(request, salEntr);
      //log("result: $result");
      result.fold(
        (exception) {
          _showLoadingDialog(context, exception.toString());
        },
        (status) {
          // Si la acción es "salida", resetear el temporizador (reemplaza con tu lógica)
          if (salEntr == "salida") {
            // Aquí deberías actualizar el estado del temporizador
            _stopwatch.reset();
            
          }
          _getWorkday();
        },
      );

      setState(() {
        _isApiCallInProgress = false;
      });
    } catch(e, stacktrace){     
      print("Error: $e");
      print("Stack Trace: $stacktrace");
    }
  }
  Future <void> _getTodayWork() async{
   
    final context = this.context;
    try{
      final result = await sl<WorkdayRepository>().getTodayWork();
      //log("result: $result");
      result.fold(
        (exception) {

          _showLoadingDialog(context, exception.toString());
          
        },
        (workdayDayStatus) {
          if(mounted){
            setState(() {
              _workdayDayStatus = workdayDayStatus;
              _isWorkdayStarted = workdayDayStatus.startWorkDay == 1;
            });
            setStatusFromDb(workdayDayStatus);
            
          }
        },
      );
      setState(() {
        _isApiCallInProgress = false;
      });
    } catch(e, stacktrace){     
      print("Error: $e");
      print("Stack Trace: $stacktrace");
    }

  }

  Future<void> clearUserData() async{
    await secureStorage.delete(key: 'auth_token');
    await secureStorage.delete(key: 'login_code');
    await secureStorage.delete(key: 'administrators_id');
    await secureStorage.delete(key: 'user_name');
    await secureStorage.delete(key: 'company_name');
    await secureStorage.delete(key: 'IDCLIENTE');
  }
  // Función para obtener el código de login (simulada)
  List<String> getLoginCode() {
    // Aquí puedes obtener el código de login desde donde lo guardes (por ejemplo, SharedPreferences, etc.)
    return ["22G3", "22GH"];  // Ejemplo de retorno
  }
  // Función para mostrar una alerta
  void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
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
  
  Map<String, int> calculateTotalTime(List<WorkDayRecord> records) {
    int sumHr = 0;
    int sumMin = 0;
    int sumSec = 0;
    bool btnFin = false;

    for (var record in records) {
      if (record.dateFin == null) {
        btnFin = true;
      }

      final start = DateTime.parse(record.dateIni);
      final end = record.dateFin != null ? DateTime.parse(record.dateFin!) : DateTime.now();
      final duration = end.difference(start);

      sumHr += duration.inHours;
      sumMin += duration.inMinutes % 60;
      sumSec += duration.inSeconds % 60;
    }

    return {"hr": sumHr, "min": sumMin, "sec": sumSec, "btnFin": btnFin ? 1 : 0};
  }
  
  void setStatusFromDb(WorkdayDayStatus workdayDayStatus) {
    bool btnFin = false;

    if (workdayDayStatus.records.isEmpty) {
      // Si no hay registros, habilitamos "entrada" y deshabilitamos "salida"
      
      setState(() {
        _isWorkdayStarted = true;
        _isRunning = true;
      });
    } else {
      // Si hay registros, calculamos el tiempo
      final result = calculateTotalTime(workdayDayStatus.records);
      final sumHr = result["hr"];
      final sumMin = result["min"];
      final sumSec = result["sec"];
      btnFin = result["btnFin"] == 1;
      
      setState(() {
        _timeElapsed = _formatDuration(Duration(hours: sumHr!, minutes: sumMin!, seconds: sumSec!));
        _initialElapsedTime = Duration(hours: sumHr, minutes: sumMin, seconds: sumSec);
      });
      
      if (btnFin) {
        setState((){
          _isWorkdayStarted = true;
          _isRunning = true;
        });
        _startTimer();

      } else {
         setState((){
          _isWorkdayStarted = true;
          _isRunning = false;
        });
      }
    }

    // Actualizar el estado del temporizador y la interfaz de usuario
    if (workdayDayStatus.startWorkDay == 1) {
      
      // Si hay registros, calculamos el tiempo
      final result = calculateTotalTime(workdayDayStatus.records);
      final sumHr = result["hr"];
      final sumMin = result["min"];
      final sumSec = result["sec"];
      btnFin = result["btnFin"] == 1;
      
      setState(() {
        _timeElapsed = _formatDuration(Duration(hours: sumHr!, minutes: sumMin!, seconds: sumSec!));
        _initialElapsedTime = Duration(hours: sumHr, minutes: sumMin, seconds: sumSec);
      });

      if (btnFin) {
        setState((){
          _isWorkdayStarted = true;
          _isRunning = true;
        });
        _startTimer();

      } else {
         setState((){
          _isWorkdayStarted = true;
          _isRunning = false;
        });
      }      

    } else {
      setState(() {
        _isWorkdayStarted = false;
        _isRunning = false;
        _timeElapsed = _formatDuration(Duration.zero);
      });
       
    }
  }

}
