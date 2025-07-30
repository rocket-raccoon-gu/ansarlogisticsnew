import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'dart:developer';

class CallLogs {
  static final CallLogs _instance = CallLogs._internal();
  factory CallLogs() => _instance;
  CallLogs._internal();

  void call(String phoneNumber, Function()? onTapClose) async {
    try {
      log("📞 Attempting to call: $phoneNumber");

      bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);

      if (onTapClose != null && res == true) {
        log("✅ Call initiated successfully");
        onTapClose();
      } else if (res == false) {
        log("❌ Call initiation failed");
      } else {
        log("⚠️ Call result is null");
      }
    } catch (e) {
      log("❌ Error making call: $e");
    }
  }

  // Helper method to format phone number
  String formatPhoneNumber(String phoneNumber) {
    String contactsplit =
        phoneNumber.length < 8 ? "+974${phoneNumber}" : "${phoneNumber}";

    log("📱 Formatted phone number: $contactsplit");
    return contactsplit;
  }

  // Method to handle call with proper formatting
  Future<void> handleCall(String phoneNumber, Function()? onTapClose) async {
    String formattedNumber = formatPhoneNumber(phoneNumber);
    call(formattedNumber, onTapClose);
  }
}
