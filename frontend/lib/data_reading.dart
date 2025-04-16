import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

class DataParser {
  DataParser();

  List<int> scaleToRange(List<double> values, double maxScale,
      {double minScale = 0}) {
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

  Future<List<List<double>>> readTestCSV() async {
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

  Future<List<List<double>>> readTest2CSV() async {
    final csvContent = await rootBundle.loadString('datafiles/test2.csv');
    List<List<dynamic>> rawCsv =
        const CsvToListConverter(fieldDelimiter: '\t').convert(csvContent);
    List<List<double>> parsed = [];
    int index = 0;

    while (index < rawCsv.length) {
      List<double> row = rawCsv[index].sublist(1, 17).map((item) {
        if (item is num) return item.toDouble();
        return double.tryParse(item.toString()) ?? 0.0;
      }).toList();
      parsed.add(row);
      index++;
    }
    return parsed;
  }

  List<List<int>> cleanData(List<List<double>> data) {
    List<List<int>> cleanData = List.generate(
        data.length, (index) => List.filled(data[index].length, 0));

    for (int i = 0; i < 16; i++) {
      List<double> newDataRow = [];
      for (int j = 0; j < data.length; j++) {
        newDataRow.add(data[j][i]);
      }
      List<int> cleanNew = scaleToRange(newDataRow, 450);
      for (int j = 0; j < cleanNew.length; j++) {
        cleanData[j][i] = cleanNew[j];
      }
    }
    return cleanData;
  }

  List<List<int>> cleanChannelPlotsData(List<List<double>> data) {
    List<List<int>> cleanData = List.generate(
        data.length, (index) => List.filled(data[index].length, 0));

    for (int i = 0; i < 16; i++) {
      List<double> newDataRow = [];
      for (int j = 0; j < data.length; j++) {
        newDataRow.add(data[j][i]);
      }
      List<int> cleanNew = scaleToRange(newDataRow, 35);
      for (int j = 0; j < cleanNew.length; j++) {
        cleanData[j][i] = cleanNew[j];
      }
    }
    List<List<int>> cleanedIndexedChannels = indexChannels(cleanData);
    return cleanedIndexedChannels;
  }

  Future<List<List<int>>> parseTestCSV(int index, bool channel) async {
    List<List<double>> data = await readTest2CSV();
    if (127 + index * 127 > data.length) {
      if (channel) {
        return cleanChannelPlotsData(data);
      } else {
        return cleanData(data);
      }
    } else {
      List<List<double>> frame =
          data.sublist(0 + index * 127, 127 + index * 127);
      if (channel) {
        return cleanChannelPlotsData(frame);
      } else {
        return cleanData(frame);
      }
    }
  }

  List<List<int>> indexChannels(List<List<int>> data) {
    List<List<int>> channelsIndexed =
        List.filled(16, List.filled(data.length, 0));
    for (int i = 0; i < 16; i++) {
      for (int j = 0; j < data.length; j++) {
        channelsIndexed[i][j] = data[j][i];
      }
    }
    return channelsIndexed;
  }
}
