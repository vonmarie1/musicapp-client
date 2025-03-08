import 'dart:io';

class ServerConstants {
  // Automatically select server URL based on the platform
  static String serverURL = Platform.isAndroid
      ? 'http://10.0.2.2:8000' // Android Emulator
      : 'http://localhost:8000'; // Web or Desktop
}
