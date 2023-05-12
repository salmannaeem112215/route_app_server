import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/users.dart';

class DriversSocketApi {
  DriversSocketApi(this.driversCollection);

  final DbCollection driversCollection;
  final List<WebSocketChannel> _sockets = [];

  Handler get router {
    return webSocketHandler((WebSocketChannel socket) {
      socket.stream.listen((message) async {
        final data = json.decode(message);
        if (data['action'] == 'ADD') {
          print(User.addJson(data['payload']));
          await driversCollection
              .insertOne(User.fromJson(data['payload']).toJson());
        }

        if (data['action'] == 'DELETE') {
          print(data['payload']);
          await driversCollection.deleteOne({
            '_id': ObjectId.fromHexString(data['payload']),
            // '_id': data['payload'],
          });
        }
        if (data['action'] == 'DELETE_MULTIPLE') {
          final adminsID = data['payload'] as List;
          for (int i = 0; i < adminsID.length; i++) {
            await driversCollection.deleteOne({
              '_id': ObjectId.fromHexString(adminsID[i]),
            });
          }
        }

        if (data['action'] == 'UPDATE') {
          final filter =
              where.eq('_id', ObjectId.fromHexString(data['payload']['_id']));
          await driversCollection.replaceOne(
              filter, User.fromJson(data['payload']).toJson());
        }

        final driversJson = await driversCollection.find().toList();
        final String encodedDrivers = json.encode(driversJson);
        for (final ws in _sockets) {
          ws.sink.add(encodedDrivers);
        }
      });

      _sockets.add(socket);
    });
  }
}
