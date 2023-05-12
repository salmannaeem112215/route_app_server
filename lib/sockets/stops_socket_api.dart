import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/track.dart';

class StopsSocketApi {
  StopsSocketApi(this.stopsCollection);

  final DbCollection stopsCollection;
  final List<WebSocketChannel> _sockets = [];

  Handler get router {
    return webSocketHandler((WebSocketChannel socket) {
      socket.stream.listen((message) async {
        final data = json.decode(message);
        print(data);
        if (data['action'] == 'ADD') {
          await stopsCollection
              .insertOne(Stop.fromJson(data['payload']).toJson());
        }

        if (data['action'] == 'DELETE') {
          print(data['payload']);
          await stopsCollection.deleteOne({
            '_id': ObjectId.fromHexString(data['payload']),
            // '_id': data['payload'],
          });
        }
        if (data['action'] == 'DELETE_MULTIPLE') {
          final adminsID = data['payload'] as List;
          for (int i = 0; i < adminsID.length; i++) {
            await stopsCollection.deleteOne({
              '_id': ObjectId.fromHexString(adminsID[i]),
            });
          }
        }

        if (data['action'] == 'UPDATE') {
          final filter =
              where.eq('_id', ObjectId.fromHexString(data['payload']['_id']));
          await stopsCollection.replaceOne(
              filter, Stop.fromJson(data['payload']).toJson());
        }

        final adminsJson = await stopsCollection.find().toList();
        final String encodedAdmins = json.encode(adminsJson);
        for (final ws in _sockets) {
          ws.sink.add(encodedAdmins);
        }
      });

      _sockets.add(socket);
    });
  }
}
