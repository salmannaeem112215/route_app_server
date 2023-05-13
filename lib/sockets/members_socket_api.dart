import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/users.dart';

class MembersSocketApi {
  MembersSocketApi(this.membersCollection);

  final DbCollection membersCollection;
  final List<WebSocketChannel> _sockets = [];

  Handler get router {
    return webSocketHandler((WebSocketChannel socket) {
      socket.stream.listen((message) async {
        final data = json.decode(message);
        print(data);
        if (data['action'] == 'ADD') {
          await membersCollection
              .insertOne(User.fromJson(data['payload']).toJson());
        }

        if (data['action'] == 'DELETE') {
          await membersCollection.deleteOne({
            '_id': ObjectId.fromHexString(data['payload']),
          });
        }
        if (data['action'] == 'DELETE_MULTIPLE') {
          final adminsID = data['payload'] as List;
          for (int i = 0; i < adminsID.length; i++) {
            await membersCollection.deleteOne({
              '_id': ObjectId.fromHexString(adminsID[i]),
            });
          }
        }

        if (data['action'] == 'UPDATE') {
          final filter =
              where.eq('_id', ObjectId.fromHexString(data['payload']['_id']));
          await membersCollection.replaceOne(
              filter, User.fromJson(data['payload']).toJson());
        }

        final membersJson = await membersCollection.find().toList();
        final String encodedMembers = json.encode(membersJson);
        for (final ws in _sockets) {
          ws.sink.add(encodedMembers);
        }
      });

      _sockets.add(socket);
    });
  }
}
