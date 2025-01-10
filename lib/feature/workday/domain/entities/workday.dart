import 'package:timecontrol/feature/workday/domain/entities/wokday_sum_hours.dart';

class Workday {
  final int? id;
  final int? administratorsId;
  final int? delIdCliente;
  final String? dia;
  final String? horas;
  final String? rrhhWorkdayIds;
  final String? ips;
  final String? tiempoTrabajado;
  final String? comment;
  final int? status;
  final SumHours? sumHours;

  Workday({
    this.id,
    this.administratorsId,
    this.delIdCliente,
    this.dia,
    this.horas,
    this.rrhhWorkdayIds,
    this.ips,
    this.tiempoTrabajado,
    this.comment,
    this.status,
    this.sumHours,
  });

  factory Workday.fromJson(Map<String, dynamic> json) {
    return Workday(
      id: _parseInt(json['id']),
      administratorsId: _parseInt(json['administrators_id']),
      delIdCliente: _parseInt(json['DEL_IDCLIENTE']),
      dia: json['dia'],
      horas: json['horas'],
      rrhhWorkdayIds: json['rrhh_workday_ids'],
      ips: json['ips'],
      tiempoTrabajado: json['tiempo_trabajado'],
      comment: json['comment'],
      status: _parseInt(json['status'].toString()),
      sumHours: json['sum_horas'] != null ? SumHours.fromJson(json['sum_horas']) : null,
    );
  }

  // Función para manejar valores nulos o vacíos al parsear un número
  static int _parseInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 0; // Retorna 0 si el valor es nulo o vacío
    }
    return int.tryParse(value.toString()) ?? 0; // Retorna 0 si no puede parsearse
  }
}