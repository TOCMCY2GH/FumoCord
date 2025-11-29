import 'client.dart';

class Admin extends Client {
  @override
  bool admin = true;

  Admin(super.socket, [super.name]) : super();
}
