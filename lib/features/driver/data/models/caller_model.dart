import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class CallLogs {
  void call(String text, Function()? onTapClose) async {
    bool? res = await FlutterPhoneDirectCaller.callNumber(text);

    if (onTapClose != null && res == true) {
      onTapClose();
    }
  }
}
