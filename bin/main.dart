import 'dart:io';

import 'package:dashboard_app_io/dashboard_app_io.dart';
import 'package:dashboard_app_io/sockets/admins_socket_api.dart';
import 'package:dashboard_app_io/sockets/drivers_socket_api.dart';
import 'package:dashboard_app_io/sockets/members_socket_api.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:shelf_router/shelf_router.dart';

void main(List<String> arguments) async {
  // Connect and load collection

  print('hiii');
  final db = await Db.create(MONGO_CONN_URL);
  await db.open();

  final DbCollection routesCollection;
  final DbCollection busesCollection;
  final DbCollection membersCollection;
  final DbCollection adminsCollection;
  final DbCollection driversCollection;

  busesCollection = db.collection(BUSES_COLLECTION);
  routesCollection = db.collection(ROUTES_COLLECTION);
  membersCollection = db.collection(MEMBERS_COLLECTION);
  adminsCollection = db.collection(ADMINS_COLLECTION);
  driversCollection = db.collection(DRIVERS_COLLECTION);
  // final DbCollection tracksCollection;

  // final DbCollection trackingCollection;
  // final DbCollection stopsCollection;

  // tracksCollection = db.collection(TRACKS_COLLECTION);
  // trackingCollection = db.collection(TRACKING_COLLECTION);
  // stopsCollection = db.collection(STOPS_COLLECTION);

  // Create server
  final app = Router();

  // Create routes
  app.mount('/$BUSES_WEBSOCKET', BusesSocketApi(busesCollection).router);
  app.mount('/$ROUTES_WEBSOCKET', RoutesSocketApi(routesCollection).router);
  app.mount('/$ADMINS_WEBSOCKET', AdminsSocketApi(adminsCollection).router);
  app.mount('/$DRIVERS_WEBSOCKET', DriversSocketApi(driversCollection).router);
  app.mount('/$MEMBERS_WEBSOCKET', MembersSocketApi(membersCollection).router);

  // Listen for incoming connections
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(handleCors())
      .addHandler(app);

  withHotreload(() => serve(handler, InternetAddress.anyIPv4, PORT));
}
