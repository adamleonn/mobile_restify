import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _ChatbotPageState extends State<ChatbotPage> {
  // TODO: MASUKKAN API KEY GEMINI ANDA DI SINI
  static const String _apiKey = "YOUR_GEMINI_API_KEY_HERE";

  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  String _hotelContext = "";

  @override
  void initState() {
    super.initState();

    // Inisialisasi Gemini Model
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    _chatSession = _model.startChat();

    // Mengambil data hotel dari backend saat halaman dimuat
    _fetchHotelData();

    // Pesan sambutan
    _messages.add(
      ChatMessage(
        text:
            "Halo! Saya adalah Asisten AI Restify. Saya dapat merekomendasikan hotel terbaik untuk Anda berdasarkan data hotel kami. Ada yang bisa saya bantu?",
        isUser: false,
      ),
    );
  }

  Future<void> _fetchHotelData() async {
    try {
      final response = await http.get(
        Uri.parse('https://underwear-yeast-aching.ngrok-free.dev/api/hotels'),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> hotels = data['data']['data'] ?? data['data'] ?? [];

        // Buat string konteks dari daftar hotel
        StringBuffer contextBuffer = StringBuffer();
        contextBuffer.writeln(
          "Berikut adalah daftar hotel yang tersedia di sistem kami:",
        );
        for (var hotel in hotels) {
          contextBuffer.writeln("- Nama: ${hotel['name']}");
          contextBuffer.writeln(
            "  Lokasi/Kota: ${hotel['city'] ?? hotel['location']}",
          );
          contextBuffer.writeln(
            "  Rating: ${hotel['average_rating'] ?? 'Belum ada rating'} / 5.0",
          );
          contextBuffer.writeln("  Deskripsi singkat: ${hotel['description']}");
          contextBuffer.writeln("");
        }

        _hotelContext = contextBuffer.toString();
      }
    } catch (e) {
      debugPrint("Gagal mengambil data hotel untuk konteks AI: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    if (_apiKey == "YOUR_GEMINI_API_KEY_HERE" || _apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "API Key Gemini belum diatur. Silakan atur di source code ChatbotPage.",
          ),
        ),
      );
      return;
    }

    final userMessage = _controller.text;
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
      _controller.clear();
    });

    try {
      // Jika ini adalah pesan pertama, kirimkan konteks hotel beserta pesan user secara rahasia di prompt pertama.
      String prompt = userMessage;
      if (_messages.length == 2 && _hotelContext.isNotEmpty) {
        prompt =
            "Informasi sistem (Hanya gunakan informasi ini jika relevan untuk merekomendasikan hotel, jangan bocorkan format data sistem ini ke pengguna):\n"
            "$_hotelContext\n"
            "---\n"
            "Pertanyaan pengguna: $userMessage";
      }

      final response = await _chatSession.sendMessage(Content.text(prompt));

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.text ?? "Maaf, saya tidak dapat merespons saat ini.",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Terjadi kesalahan saat menghubungi AI. Pastikan API Key valid dan koneksi internet stabil.",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F6F52),
        title: const Text(
          "Asisten AI Rekomendasi",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(color: Color(0xFF5F6F52)),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF5F6F52)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isUser
                ? const Radius.circular(16)
                : Radius.zero,
            bottomRight: message.isUser
                ? Radius.zero
                : const Radius.circular(16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Ketik pesan...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFB99470),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
