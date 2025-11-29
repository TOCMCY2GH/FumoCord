import 'Dart:io';
import 'package:fumo_cord/admin.dart';

void main() async {
  Socket? socket;
  for (var i = 1; i <= 10; i++) {
    try {
      socket = await Socket.connect("127.0.0.1", 4040);
      break;
    } catch (e) {
      print("Failed to connect to the chat server ᗜ⁔ᗜ, retrying...)");
    }
  }
  var client = Admin(socket!);

  await Future.wait([client.receive(socket), client.send(socket)]);
}
