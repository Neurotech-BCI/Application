import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math' as math;

class DataParser {
  DataParser();

  List<List<int>> averageEveryXRows(int x, List<List<int>> matrix) {
    if (x <= 0) throw ArgumentError.value(x, 'x must be > 0');
    final rowCount = matrix.length;
    if (rowCount == 0) return [];
    final colCount = matrix[0].length;
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

  List<List<int>> averageEveryXColumns(int x, List<List<int>> matrix) {
    if (x <= 0) throw ArgumentError.value(x, 'x must be > 0');
    final rowCount = matrix.length;
    if (rowCount == 0) return [];
    final colCount = matrix[0].length;
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

  List<List<double>> parseCsvWithBandPass(String csvBody) {
    const fs = 127.0;
    const lowCut = 0.5;
    const highCut = 40.0;
    final f0 = (lowCut + highCut) / 2;
    final bw = highCut - lowCut;
    final q = f0 / bw;

    final filters = List<BandPassFilter>.generate(
      16,
      (_) => BandPassFilter(fs: fs, f0: f0, q: q),
    );

    final result = <List<double>>[];
    final lines = csvBody.trim().split('\n');
    if (lines.length <= 1) return result;

    bool isFirstSample = true;
    for (var line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cols = line.split(',');
      if (cols.length < 17) continue;

      final raw =
          cols.sublist(1, 17).map((s) => double.tryParse(s) ?? 0.0).toList();

      if (isFirstSample) {
        for (var ch = 0; ch < filters.length; ch++) {
          filters[ch].reset(raw[ch]);
        }
        result.add(raw);
        isFirstSample = false;
      } else {
        final filtered = List<double>.generate(
          16,
          (ch) => filters[ch].process(raw[ch]),
        );
        result.add(filtered);
      }
    }

    return result;
  }
}

class BandPassFilter {
  final double fs;
  final double f0;
  final double q;

  late final double b0, b1, b2, a1, a2;

  double _x1 = 0, _x2 = 0;
  double _y1 = 0, _y2 = 0;

  BandPassFilter({
    required this.fs,
    required this.f0,
    required this.q,
  }) {
    final omega = 2 * math.pi * f0 / fs;
    final alpha = math.sin(omega) / (2 * q);
    final cosw = math.cos(omega);

    final a0 = 1 + alpha;
    b0 = alpha / a0;
    b1 = 0.0;
    b2 = -alpha / a0;
    a1 = -2 * cosw / a0;
    a2 = (1 - alpha) / a0;
  }

  void reset(double seed) {
    _x1 = _x2 = seed;
    _y1 = _y2 = seed;
  }

  double process(double x0) {
    final y0 = b0 * x0 + b1 * _x1 + b2 * _x2 - a1 * _y1 - a2 * _y2;

    _x2 = _x1;
    _x1 = x0;
    _y2 = _y1;
    _y1 = y0;

    return y0;
  }
}
