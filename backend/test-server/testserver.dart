import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'dart:async';

Future<Response> dataController(Request request) async {
  if (request.method == 'GET') {
    final responseBody = jsonEncode({'headers': 'test'});
    return Response.ok(
      responseBody,
      headers: {'Content-Type': 'application/json'},
    );
  }
  return Response.notFound('Endpoint not found');
}

void main(List<String> args) async {
  final router = Router();

  router.get('/data', (Request request) => dataController(request));

  var handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, 'localhost', 5000);

  print('Server listening on port ${server.port}');
}
