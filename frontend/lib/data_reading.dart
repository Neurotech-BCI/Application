import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

class DataParser {
  DataParser();

  List<int> scaleToRange(List<double> values,
      {double minScale = 0, double maxScale = 500}) {
    if (values.isEmpty) return [];

    double minValue = values.reduce((a, b) => a < b ? a : b);
    double maxValue = values.reduce((a, b) => a > b ? a : b);

    if (minValue == maxValue) {
      return List.filled(values.length, ((minScale + maxScale) / 2).toInt());
    }

    return values.map((value) {
      return (((value - minValue) / (maxValue - minValue)) *
                  (maxScale - minScale) +
              minScale)
          .toInt();
    }).toList();
  }

  Future<List<List<double>>> readCSV() async {
    final csvContent = await rootBundle.loadString('datafiles/test.csv');
    List<List<dynamic>> rawCsv =
        const CsvToListConverter(fieldDelimiter: '\t').convert(csvContent);

    List<dynamic> flat = rawCsv[0];

    List<List<double>> parsed = [];
    int index = 1;

    while (index + 15 < flat.length) {
      List<double> row = flat.sublist(index, index + 16).map((item) {
        if (item is num) return item.toDouble();
        return double.tryParse(item.toString()) ?? 0.0;
      }).toList();
      parsed.add(row);
      index += 16 + 15;
    }
    return parsed;
  }

  List<List<int>> cleanData(List<List<double>> data) {
    List<List<int>> cleanData = List.generate(
        data.length, (index) => List.filled(data[index].length, 0));

    for (int i = 0; i < data.length; i++) {
      cleanData[i] = scaleToRange(data[i]);
    }
    return cleanData;
  }

  Future<List<List<int>>> parseCSV(int index) async {
    List<List<double>> data = await readCSV();
    if (127 + index * 127 > data.length) {
      return cleanData(data);
    } else {
      List<List<double>> frame =
          data.sublist(0 + index * 127, 127 + index * 127);
      return cleanData(frame);
    }
  }
}
