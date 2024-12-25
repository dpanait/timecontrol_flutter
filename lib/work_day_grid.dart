import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WorkdayGrid extends StatefulWidget {
  @override
  _WorkdayGridState createState() => _WorkdayGridState();
}

class _WorkdayGridState extends State<WorkdayGrid> {
  final int _itemsPerPage = 5; // Cantidad de items por página
  int _currentPage = 1; // Página actual
  bool _isLoading = false; // Estado de carga
  List<dynamic> _workdays = []; // Datos de las jornadas laborales
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchWorkdays();
  }

  Future<void> _fetchWorkdays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.example.com/workdays?page=$_currentPage&limit=$_itemsPerPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _workdays = data['workdays'];
          _totalPages = data['totalPages'];
        });
      } else {
        throw Exception('Failed to load workdays');
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToPage(int page) {
    if (page > 0 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _fetchWorkdays();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Jornadas Laborales"),
      ),
      body: Column(
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("Fecha: ${workday['date']}"),
                          Text("Duración: ${workday['duration']}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed:
                    _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
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
        ],
      ),
    );
  }
}
