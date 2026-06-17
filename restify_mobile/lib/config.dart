import 'dart:convert';

class Config {
  // Base URL untuk koneksi API ke Backend Laravel
  static const String baseUrl = 'https://underwear-yeast-aching.ngrok-free.dev';

  // API Key Gemini untuk Chatbot AI (Ter-obfuscate dalam format Base64)
  static String get geminiApiKey {
    const String encodedKey = 'QVEuQWI4Uk42TDQzaEZGbnF3Z0lzekdQT3pOQUR0RzF5cFl6ZFpRMXNIRG53WWtvQXkzVFE=';
    return utf8.decode(base64.decode(encodedKey));
  }
}
