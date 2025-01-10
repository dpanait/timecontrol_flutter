class WorkDayRecord {
  String dateIni;
  String? dateFin;

  WorkDayRecord({
    required this.dateIni,
    this.dateFin,
  });

  // Método para convertir JSON a objeto de tipo Record
  factory WorkDayRecord.fromJson(Map<String, dynamic> json) {
    return WorkDayRecord(
      dateIni: json['date_ini'],
      dateFin: json['date_fin'],
    );
  }

  // Método para convertir objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'date_ini': dateIni,
      'date_fin': dateFin,
    };
  }
}