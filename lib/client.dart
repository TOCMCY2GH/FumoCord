import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:utf_convert/utf_convert.dart';

class Client {
  late String? name;
  late Socket socket;
  bool connected = true;
  bool admin = false;
  List<String> clients = [];

  Client(Socket socket, [String? name]) {
    this.socket = socket;
    this.name = name;
  }

  bool isConnected() => connected;
  bool isAdmin() => admin;
  String getName() => name ?? "";

  Future<void> receive(Socket serverSocket) async {
    int width = stdout.terminalColumns;
    int height = stdout.terminalLines;
    double msgPaddingX(String msg) => ((width - msg.length) / 2);
    double msgPaddingY(String msg) => ((height - msg.length) / 2);
    String msgOffsyncX(String msg) =>
        (msgPaddingX(msg) != msgPaddingX(msg).toInt().toDouble()) ? " " : "";
    String msgOffsyncY(String msg) =>
        (msgPaddingY(msg) != msgPaddingY(msg).toInt().toDouble()) ? " " : "";

    stdout.write(
      "${"M" * width * msgOffsyncY("M" * 19).length}${"M" * width * msgPaddingY("M" * 19).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MMMMMMMWNKOkxolc:o0NXXXXXXXXXNXkc:cldxk0XNWMMMMMMM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MMMMMWKxlc::;;;:::cllccccccccllc:::::;::cokXMMMMMM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MMMMWOl::::;:::;::;:::::::::::::::::;::;:::oKWMMMM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MMMNkc:;:::;;:::::::::;;:::::;::::;;::::::::l0WMMM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MMNkc;;::::::::::;:::::::::::::::::;:;:::::::l0WMM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MWOc::cdddddddddoc;:::::::::::::cdddddddddoc::lKMM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MKl:::xNWMMMMMMWXd:::::::;::;:::kNWWMMMWWWXd:::dXM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}Xd:;:cOWMMMMMMMMNx:::::::;:::::cOWMMMMMMMMNx:::ckW${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}Oc::;:kWMMMMMMMMXd::::::::::::::kWMMMMMMMMXd::::oK${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}d:::::l0WMMMMMMWOc::::::::::::::lKWMMMMMMWOc::::ck${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}l::::::lOXWWWNKxc::::;:::;:::::::lOXWWWNKxc:;::::d${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}:;:;:::::coddoc:::ldoc:::;::cddc:::coddoc:;::::::l${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}::::::::;:::::::;;:lddddddddddl::::;;;;::::::::::c${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}:::::;;::;;::::::;:::::ccc:::::::::;::;::::::::::c${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}:;::;;:::::::::::::::::::;;:::;::::::::::::::::::l${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}dc:::::;:::okkxolc:::::::;;::::ccldxkxl::::::;::lx${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}WKkdc:::::::ld0NNXK0OOkkkkkkOO0KXNXOoc::::;::ldOXW${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MMMWX0xol::::dKWMMMMMMMMMMMMMMMMMMW0l:::cldk0NWMMM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * msgOffsyncX("M" * 50).length}${"M" * msgPaddingX("M" * 50).toInt()}MMMMMMWNKkocoKWMMMMMMMMMMMMMMMMMMMMWOlldOXWMMMMMMM${"M" * msgPaddingX("M" * 50).toInt()}${"M" * width * msgPaddingY("M" * 19).toInt()}",
    );
    await Future.delayed(Duration(seconds: 6));

    serverSocket.listen(
      (data) {
        width = stdout.terminalColumns;
        height = stdout.terminalLines;
        var header = "";
        stdout.write('\x07');
        stdout.write('\x1B[2J\x1B[0;0H');
        // \x07 makes noification sound
        // \x1bM scroll up one line
        // \x1B[2J clears cmd \x1B[0;0H sets cursor to (0,0), \x1B converts to Escape code
        // VT100 escape codes
        // https://www2.ccs.neu.edu/research/gpc/VonaUtils/vona/terminal/vtansi.html
        List<Map<String, dynamic>> infoMaps = decodeDynamic(data)
            .split("\n")
            .where((line) => line.trim().isNotEmpty)
            .map((line) => jsonDecode(line) as Map<String, dynamic>)
            .toList();

        for (var map in infoMaps) {
          String historyMsg = map["history"];
          clients = map["clients"].cast<String>();
          String? message = map["message"];

          var clientsMsg = clients.join(" - ");

          var historyLines = historyMsg.split('\n');
          if (historyLines.length >= height - 6) {
            var i = 0;
            while (i <= historyLines.length - (height - 6)) {
              historyLines.removeAt(i);
            }
          }
          historyMsg = historyLines.join('\n');

          header +=
              "${"=" * width}${msgOffsyncX("FumoCord")}${" " * msgPaddingX("FumoCord").toInt()}FumoCord${" " * msgPaddingX("FumoCord").toInt()}";
          header +=
              "${"=" * width}${msgOffsyncX("Online Users")}${" " * msgPaddingX("Online Users").toInt()}Online Users${" " * msgPaddingX("Online Users").toInt()}";
          header += msgOffsyncX(clientsMsg) +
              " " * msgPaddingX(clientsMsg).toInt() +
              clientsMsg +
              " " * msgPaddingX(clientsMsg).toInt();
          header += "=" * width + historyMsg;
          stdout.write(header);
          stdout.write(message);
          if (name != null && message != "") stdout.write("\n");
          if (name != null) stdout.write("$name: ");
        }
      },
      onDone: () {
        print('Server closed the connection');
        connected = false;
      },
      onError: (error) {
        print('Error: $error');
        connected = false;
      },
    );
  }

  String decodeDynamic(List<int> bytes) {
    // Try UTF-16 with BOM detection
    try {
      return decodeUtf8(bytes);
    } catch (_) {
      // fallback to UTF-16 just in case
      try {
        return decodeUtf16(bytes);
      } catch (_) {
        return decodeUtf16be(bytes);
      }
    }
  }

  Future<void> send(Socket serverSocket) async {
    bool listening = false;
    while (isConnected() && !listening) {
      stdin.transform(utf8.decoder).listen((input) async {
        if (name != null) stdout.write("$name: ");
        if (input != "") {
          if (name == null) {
            String type = (isAdmin()) ? "Admin" : "Client";
            serverSocket.writeln("($type)$input");
            name = input.trim();
          } else {
            serverSocket.writeln(input);
          }
        }
      });
      listening = true;
    }
    listening = false;
  }
}
