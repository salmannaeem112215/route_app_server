import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/stop.dart';

class PathsSocketApi {
  PathsSocketApi(this.pathsCollection);

  final DbCollection pathsCollection;
  final List<WebSocketChannel> _sockets = [];

  Handler get router {
    return webSocketHandler((WebSocketChannel socket) {
      socket.stream.listen((message) async {
        final data = json.decode(message);
        print(data);
        if (data['action'] == 'ADD') {
          await pathsCollection
              .insertOne(Stop.fromJson(data['payload']).toJson());
        }

        if (data['action'] == 'DELETE') {
          await pathsCollection.deleteOne({
            '_id': ObjectId.fromHexString(data['payload']),
            // '_id': data['payload'],
          });
        }
        if (data['action'] == 'DELETE_MULTIPLE') {
          final adminsID = data['payload'] as List;
          for (int i = 0; i < adminsID.length; i++) {
            await pathsCollection.deleteOne({
              '_id': ObjectId.fromHexString(adminsID[i]),
            });
          }
        }

        if (data['action'] == 'UPDATE') {
          final filter =
              where.eq('_id', ObjectId.fromHexString(data['payload']['_id']));
          await pathsCollection.replaceOne(
              filter, Stop.fromJson(data['payload']).toJson());
        }

        final pathJson = await pathsCollection.find().toList();
        final String enocdedPath = json.encode(pathJson);
        for (final ws in _sockets) {
          ws.sink.add(enocdedPath);
        }
      });

      _sockets.add(socket);
    });
  }
}
