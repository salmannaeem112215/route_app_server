import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/bus.dart';

class BusesSocketApi {
  BusesSocketApi(this.busesCollection);

  final DbCollection busesCollection;
  final List<WebSocketChannel> _sockets = [];

  Handler get router {
    return webSocketHandler((WebSocketChannel socket) {
      socket.stream.listen((message) async {
        final data = json.decode(message);
        if (data['action'] == 'ADD') {
          await busesCollection.insert(Bus.addBusJson(data['payload']));
        }

        if (data['action'] == 'DELETE') {
          print(data['payload']);
          await busesCollection.deleteOne({
            '_id': ObjectId.fromHexString(data['payload']),
            // '_id': data['payload'],
          });
        }
        if (data['action'] == 'DELETE_MULTIPLE') {
          final busesID = data['payload'] as List;
          for (int i = 0; i < busesID.length; i++) {
            await busesCollection.deleteOne({
              '_id': ObjectId.fromHexString(busesID[i]),
            });
          }
        }

        if (data['action'] == 'UPDATE') {
          final filter =
              where.eq('_id', ObjectId.fromHexString(data['payload']));
          await busesCollection.replaceOne(
              filter, Bus.addBusJson(data['payload']));

          // busesCollection
        }

        final busesJson = await busesCollection.find().toList();
        final String encodedBusses = json.encode(busesJson);
        for (final ws in _sockets) {
          ws.sink.add(encodedBusses);
        }
      });

      _sockets.add(socket);
    });
  }
}
