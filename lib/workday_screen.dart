import 'dart:async';

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WorkdayScreen extends StatefulWidget {
  @override
  _WorkdayScreenState createState() => _WorkdayScreenState();
}

class _WorkdayScreenState extends State<WorkdayScreen> {
  Stopwatch _stopwatch = Stopwatch();
  late String _timeElapsed = '00:00:00';
  late Timer? _timer;
  bool _isWorkdayStarted = false; // Estado para gestionar la jornada laboral
  bool _isRunning = false; // Estado para alternar entre Start/Stop

  // Variables para el grid
  final int _itemsPerPage = 5; // Cantidad de items por página
  int _currentPage = 0; // Página actual
  bool _isLoading = false; // Estado de carga
  List<dynamic> _workdays = []; // Datos de las jornadas laborales
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _timeElapsed = _formatDuration(Duration.zero);
    _fetchWorkdays();
  }

  @override
  void dispose() {
    _timer!.cancel();
    super.dispose();
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
    });
    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeElapsed = _formatDuration(_stopwatch.elapsed);
      });
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer!.cancel();
  }

  void _toggleStartStop() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _endWorkday() {
    _stopTimer();
    _stopwatch.reset();
    setState(() {
      _timeElapsed = _formatDuration(Duration.zero);
      _isWorkdayStarted = false;
      _isRunning = false;
    });
  }

// Función para obtener jornadas laborales
  Future<void> _fetchWorkdays() async {
    setState(() {
      _isLoading = true;
    });
    String code1 = "22G3";
    String code2 = "22GH";
    String fecha_start = "2024-12-01";
    String fecha_fin = "2024-12-31";
    String jsonPost = jsonEncode({
      'PostData': {
        'action': 'list',
        'code1': code1,
        'code2': code2,
        'fecha_start': fecha_start,
        'fecha_fin': fecha_fin
      }
    });
    // })
    try {
      int pageSize = 0;
      if (_itemsPerPage * _currentPage == 0) {
        pageSize = 0;
      } else {
        pageSize = (_itemsPerPage * _currentPage).ceil();
      }
      print("_currentPage: $_currentPage - pageSize: $pageSize");
      String url =
          'https://buygest.kuuvoo.com/pre/dani_d1/yuubbbshop/data_fichar?jtStartIndex=$_currentPage&jtPageSize=$pageSize';
      print("Url: $url");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonPost,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("data: ${data.toString()}");
        setState(() {
          _workdays = data['datas'];
          _totalPages = (int.parse(data['total']) / _itemsPerPage).ceil();
        });
      } else {
        throw Exception('Failed to load workdays');
      }
    } catch (e, stacktrace) {
      print("Error: $e");
      print("Stack Trace: $stacktrace");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToPage(int page) {
    print("page: $page - $_currentPage - $_totalPages");
    if (page >= 0 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _fetchWorkdays();
    }
  }

  List<Widget> _buildPaginationButtons() {
    List<Widget> buttons = [];

    buttons.add(ElevatedButton(
      onPressed: _currentPage > 1
          ? () {
              print("_currentPage: $_currentPage");
              _goToPage(_currentPage - 1);
            }
          : null,
      child: Text("<"),
    ));
    if (_totalPages <= 3) {
      // Si hay 3 o menos páginas, muestra todos los botones
      for (int i = 1; i <= _totalPages; i++) {
        buttons.add(_buildPageButton(i));
      }
    } else {
      // Si hay más de 3 páginas, muestra el primero, el actual, y el último, con puntos suspensivos si es necesario
      buttons.add(_buildPageButton(1));

      if (_currentPage > 2) {
        //buttons.add(_buildEllipsis());
      }

      if (_currentPage > 1 && _currentPage < _totalPages) {
        buttons.add(_buildPageButton(_currentPage));
      }

      if (_currentPage < _totalPages - 1) {
        //buttons.add(_buildEllipsis());
      }

      buttons.add(_buildPageButton(_totalPages));
    }

    buttons.add(ElevatedButton(
      onPressed: _currentPage < _totalPages
          ? () {
              print("_currentPage: $_currentPage");
              _goToPage(_currentPage + 1);
            }
          : null,
      child: Text(">"),
    ));

    return buttons;
  }

  Widget _buildPageButton(int page) {
    return ElevatedButton(
      onPressed: () => _goToPage(page),
      child: Text(page.toString()),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          _currentPage == page ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Text('...', style: TextStyle(fontSize: 20, color: Colors.black));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Workday Timer"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _timeElapsed,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isWorkdayStarted ? null : _startWorkday,
                  child: Text("Empezar"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isWorkdayStarted ? _toggleStartStop : null,
                  child: Text(_isRunning ? "Stop" : "Start"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isWorkdayStarted ? _endWorkday : null,
                  child: Text("Salir"),
                ),
              ],
            ),
            Divider(),
            // Grid de jornadas laborales
            Expanded(
              child: Column(
                children: [
                  if (_isLoading)
                    Expanded(
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
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ID: ${workday['id']}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text("Día: ${workday['dia']}"),
                                  Text("Rango fechas: ${workday['horas']}"),
                                  Text(
                                      "Total día: ${workday['tiempo_trabajado']}"),
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
                        vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildPaginationButtons(),
                      /*[
                        ElevatedButton(
                          onPressed: _currentPage > 1
                              ? () {
                                  print("_currentPage: $_currentPage");
                                  _goToPage(_currentPage - 1);
                                }
                              : null,
                          child: Text("<"),
                        ),
                        SizedBox(width: 10),
                        // Botones numerados
                        ...List.generate(_totalPages, (index) {
                          int pageNumber = index + 1;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ElevatedButton(
                              onPressed: () {
                                print(
                                    "pageNumber: $pageNumber - $_currentPage");
                                _goToPage(pageNumber);
                              },
                              child: Text(pageNumber.toString()),
                            ),
                          );
                        }),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _currentPage < _totalPages
                              ? () {
                                  print("_currentPage: $_currentPage");
                                  _goToPage(_currentPage + 1);
                                }
                              : null,
                          child: Text(">"),
                        ),
                      ],*/
                    ),
                  ),
                  /*Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _currentPage > 1
                              ? () => _goToPage(_currentPage - 1)
                              : null,
                          child: Text("Anterior"),
                        ),
                        Text("Página $_currentPage de $_totalPages"),
                        ElevatedButton(
                          onPressed: _currentPage < _totalPages
                              ? () => _goToPage(_currentPage + 1)
                              : null,
                          child: Text("Siguiente"),
                        ),
                      ],
                    ),
                  ),*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
