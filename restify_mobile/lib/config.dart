class Config {
  // Base URL untuk koneksi API ke Backend Laravel
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://underwear-yeast-aching.ngrok-free.dev',
  );

  // API Key Gemini untuk Chatbot AI
  // Anda dapat langsung mengganti string ini dengan API Key Gemini Anda (dari Google AI Studio)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}

