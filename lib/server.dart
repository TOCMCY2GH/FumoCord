import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:utf_convert/utf_convert.dart';
import 'client.dart'; // contains Client class
import 'admin.dart'; // contains Admin class

class ChatServer {
  // server socket variables
  late InternetAddress address;
  late int port;
  late ServerSocket serverSocket;

  // server data variables
  final List<Client> clients = [];
  final List<Admin> admins = [];
  final List<String> history = [];
  final List<Client> mute = [];

  // list of emotes for the server
  final Map<String, String> emojis = {
    ":smile:": "ᗜ‿ᗜ",
    ":frown:": "ᗜ⁔ᗜ",
    ":ok:": "ᗜ_ᗜ",
    ":happy:": "ᗜˬᗜ",
    ":sad:": "ᗜ˰ᗜ",
    ":cat:": "ᗜ⩊ᗜ",
    ":think:": "ᗜ ▵ ᗜ",
    ":good:": "ദ്ദി ᗜˬᗜ✧",
    ":oh:": "ᗜ.ᗜ",
    ":baka:": "➈",
    ":zun:": "🍺 ᗜˬᗜ",
  };

  // constructor for the server Class
  ChatServer() {
    address = InternetAddress(
        "0.0.0.0"); // 127.0.0.1 (local machine) 0.0.0.0 for all IPs
    port = 4040;
  }

  // open server and handle clients as they connect
  void open() async {
    // set up server
    serverSocket = await ServerSocket.bind(address, port);
    print(
      "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
      "The chat server has opened. it is bound to following parameters:\n"
      "Local adresse: ${serverSocket.address}\n"
      "Adresse(IP): ${serverSocket.address.address}\n"
      "Port: ${serverSocket.port}",
    );

    // handle clients as they connect
    await for (Socket clientSocket in serverSocket) {
      print(
        "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
        "A new client has connected to the server! their informations:\n"
        "Remote adresse: ${clientSocket.remoteAddress}\n"
        "Adresse(IP): ${clientSocket.remoteAddress.address}\n"
        "Port: ${clientSocket.port}",
      );
      connect(clientSocket);
    }
  }

  // connecting and managing client messages
  void connect(Socket clientSocket) async {
    // print chat header and message asking for user name
    await printHeader(
      clientSocket,
      "Welcome to our Fumo ᗜˬᗜ chat server!\nplease Input your username: ",
    );

    // start the listening loop that will continue receiving client messages
    clientSocket.listen(
      (data) async {
        // decode message using custom made decoding function, handles UTF8-16
        String message = decodeDynamic(data).trim();

        // creating local variables
        Client client;
        bool isAdmin = false;

        // case for new user(inputting username)
        if (!clients.any((client) => client.socket == clientSocket)) {
          // check for proper syntax before looking for username
          if (RegExp(r'\(([^()]+)\)(.*)').hasMatch(message)) {
            // getting match and double checking it's proper(unecessary)
            // don't wanna edit it incase it breaks something
            final result = RegExp(r'\(([^()]+)\)(.*)').firstMatch(message);
            while (await filter(result!.group(2).toString()) !=
                result.group(2).toString()) {
              await printHeader(
                clientSocket,
                "[Help] User name invalid.\nplease Input your username: ",
              );
            }

            // adding users, group(2) is username here(already filtered)
            if (result.group(1) == "Admin") isAdmin = true;
            clients
                .add(Client(clientSocket, result.group(2).toString().trim()));
            if (isAdmin) {
              admins
                  .add(Admin(clientSocket, result.group(2).toString().trim()));
            }

            // announcing and logging new client addition
            print(
              "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
              "Client $message(${clientSocket.remoteAddress.address}:) has joined the chat server.",
            );
            broadcast(null, "$message has joined the chat server!");
          } else {
            // case with no match, aka something broke client side in syntax
            print("no match");
          }
          // making sure user isn't muted before handling their messages
        } else if (!mute.contains(
          clients.firstWhere((client) => client.socket == clientSocket),
        )) {
          // saving non muted client to local variable
          client = clients.firstWhere(
            (client) => client.socket == clientSocket,
          );

          // replacing amm emojiCodes with actual emojis
          for (var emojiCode in emojis.keys) {
            message = message.replaceAll(emojiCode, emojis[emojiCode]!);
          }
          // filtering message
          message = await filter(message);

          // checking if the message is a chat command
          switch (message) {
            case "/help":
              // print commands depending on client type
              if (client.isAdmin()) {
                await printHeader(
                  client.socket,
                  "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] List of chat server commands:\n"
                  "/dc: Disconnects you from the chat server.\n"
                  "/pm \"[Name]\" [message]: Private message specific user.\n"
                  "/report \"[Name]\" [message]: Private message specific user.\n",
                );
              } else {
                await printHeader(
                  client.socket,
                  "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] List of chat server commands:\n"
                  "/dc: Disconnects you from the chat server.\n"
                  "/pm \"[Name]\" [message]: Private message specific user.\n"
                  "/report \"[Name]\" [message]: Private message specific user.\n"
                  "/mute \"[Name]\" [message]: mute a specific user(only for Admins).\n"
                  "/unmute \"[Name]\": unmute a specific user(only for Admins).\n"
                  "/shutdown [seconds]: shutdown server after number of seconds(only for Admins).\n",
                );
              }
              break;
            case "/dc":
              // disconect client
              disconnect(client, true);
              break;
            case "/shutdown":
              // shutdown server after 5s
              if (admins
                  .where((admin) => admin.socket == clientSocket)
                  .isNotEmpty) {
                close(5);
              }
              break;
            default:
              // cases of commands that require RegEx
              if (RegExp(r'^/pm').hasMatch(message)) {
                // save private message command match to local variable
                final result = RegExp(
                  r'^/pm\s+"([^"]+)"\s+(.*)',
                ).firstMatch(message);

                // check if match is invalid
                if (result == null) {
                  client.socket.writeln(
                    "[Help] Syntax incorrect.",
                  );
                }

                // case where match is valid
                if (result != null) {
                  // print the message to only sender and receiver
                  for (var socket in [
                    client.socket,
                    clients
                        .firstWhere(
                          (client) => client.name == result.group(1),
                        )
                        .socket,
                  ]) {
                    await printHeader(
                      socket,
                      "[PM][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] ${client.name}: ${result.group(2)}",
                    );
                  }

                  // log private message down in server(spyware)
                  print(
                    "[PM][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] ${client.name}: ${result.group(2)}",
                  );
                }
              } else if (RegExp(r'^/color').hasMatch(message)) {
                // save mute command match to local variable
                final result = RegExp(
                  r'^/mute\s+"([^"]+)"\s+(.*)',
                ).firstMatch(message);

                // check if match is invalid
                if (result == null) {
                  client.socket.writeln(
                    "[Help] Command syntax incorrect.",
                  );
                }

                // case where match is valid and user is admin
                if (result != null &&
                    admins
                        .where((admin) => admin.socket == clientSocket)
                        .isNotEmpty) {
                  // save target client to local variable
                  final targetClient = clients.firstWhere(
                    (client) => client.getName() == result.group(1),
                  );

                  // case target client is invalid
                  if (targetClient == -1) {
                    await printHeader(
                      client.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "User ${result.group(1)} couldn't be found.",
                    );
                    // case with valid target client
                  } else {
                    // printing mute announcements to admin and target client
                    await printHeader(
                      targetClient.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "You have been muted by ${client.name}, Reason: ${result.group(2)}.",
                    );
                    await printHeader(
                      client.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "User ${result.group(1)} has been muted, Reason: ${result.group(2)}.",
                    );

                    // logging mute event to server
                    print(
                      "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Client ${result.group(1)}(${targetClient.socket.address.address}) has been muted by ${client.name}, Reason: ${result.group(2)}.",
                    );

                    // adding target client to muted list
                    mute.add(targetClient);
                  }
                }
              } else if (RegExp(r'^/mute').hasMatch(message)) {
                // save mute command match to local variable
                final result = RegExp(
                  r'^/mute\s+"([^"]+)"\s+(.*)',
                ).firstMatch(message);

                // check if match is invalid
                if (result == null) {
                  client.socket.writeln(
                    "[Help] Command syntax incorrect.",
                  );
                }

                // case where match is valid and user is admin
                if (result != null &&
                    admins
                        .where((admin) => admin.socket == clientSocket)
                        .isNotEmpty) {
                  // save target client to local variable
                  final targetClient = clients.firstWhere(
                    (client) => client.getName() == result.group(1),
                  );

                  // case target client is invalid
                  if (targetClient == -1) {
                    await printHeader(
                      client.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "User ${result.group(1)} couldn't be found.",
                    );
                    // case with valid target client
                  } else {
                    // printing mute announcements to admin and target client
                    await printHeader(
                      targetClient.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "You have been muted by ${client.name}, Reason: ${result.group(2)}.",
                    );
                    await printHeader(
                      client.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "User ${result.group(1)} has been muted, Reason: ${result.group(2)}.",
                    );

                    // logging mute event to server
                    print(
                      "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Client ${result.group(1)}(${targetClient.socket.address.address}) has been muted by ${client.name}, Reason: ${result.group(2)}.",
                    );

                    // adding target client to muted list
                    mute.add(targetClient);
                  }
                }
              } else if (RegExp(r'^/unmute').hasMatch(message)) {
                // save unmute command match to local variable
                final result = RegExp(
                  r'^/unmute\s+"([^"]+)"',
                ).firstMatch(message);

                // check if match is invalid
                if (result == null) {
                  client.socket.writeln(
                    "[Help] Command syntax incorrect.",
                  );
                }

                // case where match is valid and user is admin
                if (result != null &&
                    admins
                        .where((admin) => admin.socket == clientSocket)
                        .isNotEmpty) {
                  // save target client to local variable
                  final targetClient = clients.firstWhere(
                    (client) => client.getName() == result.group(1),
                  );

                  // case target client is invalid
                  if (targetClient == -1) {
                    await printHeader(
                      client.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "User ${result.group(1)} couldn't be found.",
                    );
                    // case with valid target client that's muted
                  } else if (mute.contains(targetClient)) {
                    // printing unmute announcements to admin and target client
                    await printHeader(
                      targetClient.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "You have been unmuted by ${client.name}!",
                    );
                    await printHeader(
                      client.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "User ${result.group(1)} has been unmuted.",
                    );

                    // logging unmute event to server
                    print(
                      "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Client ${result.group(1)}(${targetClient.socket.address.address}) has been unmuted by ${client.name}.",
                    );

                    // removing target client to muted list
                    mute.remove(targetClient);
                  }
                }
              } else if (RegExp(r'^/report').hasMatch(message)) {
                // save report command match to local variable
                final result = RegExp(
                  r'^/report\s+"([^"]+)"\s+(.*)',
                ).firstMatch(message);

                // check if match is invalid
                if (result == null) {
                  client.socket.writeln(
                    "[Help] Command syntax incorrect.",
                  );
                }

                // case where match is valid
                if (result != null) {
                  // save target client to local variable
                  final targetClient = clients.firstWhere(
                    (client) => client.getName() == result.group(1),
                  );

                  // case target client is invalid
                  if (targetClient == -1) {
                    await printHeader(
                      client.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "User ${result.group(1)} couldn't be found.",
                    );
                    // case with valid target client
                  } else {
                    // printing report announcements to all admins and reporter
                    for (var admin in admins) {
                      await printHeader(
                        admin.socket,
                        "[Report][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                        "Client ${client.name} has reported ${targetClient.name} for: ${result.group(2)}.",
                      );
                    }
                    await printHeader(
                      client.socket,
                      "[Help][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
                      "Client ${result.group(1)} has been reported.",
                    );

                    // logging unmute event to server
                    print(
                      "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Client ${result.group(1)}(${targetClient.socket.address.address}) has been reported by ${client.name}, Reason: ${result.group(2)}.",
                    );
                  }
                }
              } else if (RegExp(r'^/shutdown').hasMatch(message)) {
                // save shutdown command match to local variable
                final result = RegExp(
                  r'^/shutdown\s+(\d+)',
                ).firstMatch(message);

                // check if match is invalid
                if (result == null) {
                  client.socket.writeln(
                    "[Help] Command syntax incorrect.",
                  );
                }

                // case where match is valid and user is admin
                if (result != null &&
                    admins
                        .where((admin) => admin.socket == clientSocket)
                        .isNotEmpty) {
                  // logging shutdown event to server
                  print(
                    "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Client ${client.name} has scheduled a server shutdown in ${result.group(1)} seconds.",
                  );

                  // closing server in specified time
                  close(int.parse(result.group(1)!));
                }
              } else {
                // case with no commands in message, broadcasting the message
                broadcast(client, message);
              }
          }
        }
      },
      onDone: () {
        // case incase of unexpected disconnection
        // handling announcement, logs and proper disconnection
        disconnect(
          clients.firstWhere((client) => client.socket == clientSocket),
          false,
        );
      },
    );
  }

  // custom decoder, needed due to messages switching between UTF8 and UTF16
  String decodeDynamic(List<int> bytes) {
    // try decoding with utf8
    try {
      return decodeUtf8(bytes);
    } catch (_) {
      // try decoding with utf16
      try {
        return decodeUtf16(bytes);
      } catch (_) {
        // try decoding with utf16be
        return decodeUtf16be(bytes);
      }
    }
  }

  // broadcasting the message to everyone and logging it
  void broadcast(Client? sender, String message) async {
    // case with client side message
    if (sender != null) {
      // update history logs with new message
      updateHistory(
        "[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] ${sender.name}: $message",
      );

      // print header with new history to all users
      for (var receiver in clients) {
        await printHeader(receiver.socket);
      }

      // logging the broadcast to server
      print(
        "[Broadcast][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] ${sender.name}: $message",
      );
      // case of server side broadcast
    } else {
      // update history logs with new message set as announcement
      updateHistory(
        "[Announcement][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $message",
      );

      // print header with new history to all users
      for (var receiver in clients) {
        await printHeader(receiver.socket);
      }

      // logging the announcement to server
      print(
        "[Announcement][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $message",
      );
    }
  }

  // custom filter function
  Future<String> filter(String message) async {
    List<String> words = message.split(" ");
    for (var i = 0; i < words.length; i++) {
      final filterResponse = await http.get(Uri.parse(
          "https://www.purgomalum.com/service/containsprofanity?text=${words[i]}"));
      if (filterResponse.statusCode == 200 && filterResponse.body == "true") {
        words[i] = "*" * words[i].length;
      }
    }
    return words.join(" ");
  }

  void updateHistory(String message) {
    if (history.length >= 100) history.removeAt(0);
    history.add(message);
  }

  Future<void> printHeader(Socket socket, [String? message]) async {
    String historyMsg = "";
    for (var message in history) {
      historyMsg += "$message\n";
    }
    String json = jsonEncode({
      "message": message ?? "",
      "history": historyMsg,
      "clients": clients.map((client) => client.name as String).toList(),
    });
    socket.write("$json\n");
  }

  // countdown, disconnect clients and close down server
  void close([int? seconds]) async {
    // countdown to server closing
    if (seconds != null) {
      // setting bounds to seconds input, 10 seconds - 1 hour
      if (seconds < 10) seconds = 10;
      if (seconds > 60 * 60) seconds = 60 * 60;

      // loop for minutes countdown
      while (seconds! > 60) {
        if (seconds % 60 * 60 == 0) {
          broadcast(null, "The server will close in 1 hour.");
        } else if (seconds % 60 * 10 == 0) {
          broadcast(null, "The server will close in ${seconds / 60} minutes.");
        }
        await Future.delayed(Duration(seconds: 1));
        --seconds;
      }
      // loop for seconds countdown
      while (seconds! > 0) {
        if (seconds % 60 == 0) {
          broadcast(null, "The server will close in 1 minute.");
        } else if (seconds % 10 == 0 || [5, 4, 3, 2].contains(seconds)) {
          broadcast(null, "The server will close in $seconds seconds.");
        } else if (seconds == 1) {
          broadcast(null, "The server will close in 1 second.");
        }
        await Future.delayed(Duration(seconds: 1));
        --seconds;
      }
    }

    // countdown finished
    // disconnecting all clients from the server
    for (var client in clients) {
      await printHeader(
        client.socket,
        "[Announcement][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
        "The chat server is being closed. You have been disconnected.",
      );
      await client.socket.close();
    }

    // closing down the server
    serverSocket.close();
    print(
      "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] "
      "The chat server has been closed.",
    );
  }

  // disconnecting client then announcing and logging it
  void disconnect(Client client, bool prompted) async {
    if (prompted) {
      await printHeader(
        client.socket,
        "[Announcement][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] You have been disconnected from the chat server.",
      );
    }
    broadcast(null, "${client.name} has disconnected from the chat server.");
    clients.remove(client);
    await client.socket.close();
    print(
      "[Server log][${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Client ${client.name}(${client.socket.address.address}) has been disconnected from the chat server.",
    );
  }
}
