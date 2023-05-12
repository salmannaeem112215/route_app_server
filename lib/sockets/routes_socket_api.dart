import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RoutesSocketApi {
  RoutesSocketApi(this.routes);

  final DbCollection routes;
  final List<WebSocketChannel> _sockets = [];

  Handler get router {
    return webSocketHandler((WebSocketChannel socket) {
      socket.stream.listen((message) async {
        final data = json.decode(message);

        // function to Add
        if (data['action'] == 'ADD') {
          print(data['payload']);
          final r = await routes.insert(data['payload']);
          print(r);
        }

        // function to delete
        if (data['action'] == 'DELETE') {
          print(data['payload']);
          await routes.deleteOne({
            '_id': ObjectId.fromHexString(data['payload']),
            // '_id': data['payload'],
          });
        }

        // function to Update
        if (data['action'] == 'UPDATE') {
          print(data['payload']);
          // TODO: ADD CODE TO UPDATE
        }

        // will update data in all endpoints
        final routesJson = await routes.find().toList();
        final String encodedRoutes = json.encode(routesJson);
        for (final ws in _sockets) {
          ws.sink.add(encodedRoutes);
        }
      });

      _sockets.add(socket);
    });
  }
}
