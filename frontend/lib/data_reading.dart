import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

class DataParser {
  DataParser();

  /// Groups every [x] rows, averages them (rounding to int), and emits one row per group.
  /// - Input:  matrix of size R×C
  /// - Output: matrix of size ⌈R/x⌉×C, with int averages
  List<List<int>> averageEveryXRows(int x, List<List<int>> matrix) {
    if (x <= 0) throw ArgumentError.value(x, 'x must be > 0');
    final rowCount = matrix.length;
    if (rowCount == 0) return [];
    final colCount = matrix[0].length;
    // verify rectangular
    for (var row in matrix) {
      if (row.length != colCount) {
        throw ArgumentError('All rows must have the same length');
      }
    }

    final newRowCount = (rowCount + x - 1) ~/ x;
    final result = List.generate(
      newRowCount,
      (_) => List<int>.filled(colCount, 0),
    );

    for (var i = 0; i < rowCount; i += x) {
      final chunkSize = ((i + x) <= rowCount) ? x : (rowCount - i);
      final outRow = i ~/ x;

      for (var j = 0; j < colCount; j++) {
        var sum = 0;
        for (var k = i; k < i + chunkSize; k++) {
          sum += matrix[k][j];
        }
        result[outRow][j] = (sum / chunkSize).round();
      }
    }

    return result;
  }

  /// Groups every [x] columns, averages them (rounding to int), and emits one column per group.
  /// - Input:  matrix of size R×C
  /// - Output: matrix of size R×⌈C/x⌉, with int averages
  List<List<int>> averageEveryXColumns(int x, List<List<int>> matrix) {
    if (x <= 0) throw ArgumentError.value(x, 'x must be > 0');
    final rowCount = matrix.length;
    if (rowCount == 0) return [];
    final colCount = matrix[0].length;
    // verify rectangular
    for (var row in matrix) {
      if (row.length != colCount) {
        throw ArgumentError('All rows must have the same length');
      }
    }

    final newColCount = (colCount + x - 1) ~/ x;
    final result = List.generate(
      rowCount,
      (_) => List<int>.filled(newColCount, 0),
    );

    for (var j = 0; j < colCount; j += x) {
      final chunkSize = ((j + x) <= colCount) ? x : (colCount - j);
      final outCol = j ~/ x;

      for (var i = 0; i < rowCount; i++) {
        var sum = 0;
        for (var k = j; k < j + chunkSize; k++) {
          sum += matrix[i][k];
        }
        result[i][outCol] = (sum / chunkSize).round();
      }
    }

    return result;
  }

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
    return parsed.sublist(127, parsed.length);
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

  List<List<int>> indexChannels(List<List<int>> data) {
    List<List<int>> channelsIndexed =
        List.generate(16, (_) => List.filled(data.length, 0));

    for (int j = 0; j < data.length; j++) {
      for (int i = 0; i < data[j].length; i++) {
        channelsIndexed[i][j] = data[j][i];
      }
    }
    return channelsIndexed;
  }

  List<List<double>> parseCsv(String csvBody) {
    final lines = csvBody.trim().split('\n');
    if (lines.length <= 1) return [];
    final dataLines = lines.skip(1);
    final result = <List<double>>[];
    for (var line in dataLines) {
      if (line.trim().isEmpty) continue;
      final cols = line.split(',');
      if (cols.length < 17) {
        continue;
      }
      final channelStrings = cols.sublist(1, 17);
      final channelDoubles =
          channelStrings.map((s) => double.tryParse(s) ?? 0.0).toList();
      result.add(channelDoubles);
    }
    return result;
  }
}
