import 'dart:io';

import 'package:dashboard_app_io/dashboard_app_io.dart';
import 'package:dashboard_app_io/sockets/admins_socket_api.dart';
import 'package:dashboard_app_io/sockets/drivers_socket_api.dart';
import 'package:dashboard_app_io/sockets/members_socket_api.dart';
import 'package:dashboard_app_io/sockets/paths_socket_api.dart';
import 'package:dashboard_app_io/sockets/stops_socket_api.dart';
import 'package:dashboard_app_io/sockets/tracking_socket_api.dart';
import 'package:dashboard_app_io/sockets/tracks_socket_api.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:shelf_router/shelf_router.dart';

void main(List<String> arguments) async {
  // Connect and load collection

  final db = await Db.create(MONGO_CONN_URL);
  await db.open();

  final DbCollection routesCollection;
  final DbCollection busesCollection;
  final DbCollection membersCollection;
  final DbCollection adminsCollection;
  final DbCollection driversCollection;
  final DbCollection tracksCollection;
  final DbCollection trackingsCollection;
  final DbCollection stopsCollection;
  final DbCollection pathsCollection;

  busesCollection = db.collection(BUSES_COLLECTION);
  routesCollection = db.collection(ROUTES_COLLECTION);
  membersCollection = db.collection(MEMBERS_COLLECTION);
  adminsCollection = db.collection(ADMINS_COLLECTION);
  driversCollection = db.collection(DRIVERS_COLLECTION);
  tracksCollection = db.collection(TRACKS_COLLECTION);
  trackingsCollection = db.collection(TRACKINGS_COLLECTION);
  stopsCollection = db.collection(STOPS_COLLECTION);
  pathsCollection = db.collection(PATHS_COLLECTION);

  // final DbCollection trackingCollection;

  // trackingCollection = db.collection(TRACKING_COLLECTION);

  // Create server
  final app = Router();

  // Create routes
  app.mount(
      '/$TRACKINGS_WEBSOCKET', TrackingsSocketApi(trackingsCollection).router);
  app.mount('/$BUSES_WEBSOCKET', BusesSocketApi(busesCollection).router);
  app.mount('/$ROUTES_WEBSOCKET', RoutesSocketApi(routesCollection).router);

  app.mount('/$ADMINS_WEBSOCKET', AdminsSocketApi(adminsCollection).router);
  app.mount('/$DRIVERS_WEBSOCKET', DriversSocketApi(driversCollection).router);
  app.mount('/$MEMBERS_WEBSOCKET', MembersSocketApi(membersCollection).router);

  app.mount('/$PATHS_WEBSOCKET', PathsSocketApi(pathsCollection).router);
  app.mount('/$STOPS_WEBSOCKET', StopsSocketApi(stopsCollection).router);
  app.mount('/$TRACKS_WEBSOCKET', TracksSocketApi(tracksCollection).router);

  // Listen for incoming connections
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(handleCors())
      .addHandler(app);

  withHotreload(() => serve(handler, InternetAddress.anyIPv4, PORT));
}
