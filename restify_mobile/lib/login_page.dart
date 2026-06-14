import 'package:flutter/material.dart';
import 'package:restify/forgotPass_page.dart';
import 'package:restify/signup_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recaptcha_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? recaptchaToken;
  bool isLoading = false;
  Future<void> login() async {
    setState(() {
      emailError = null;
      passwordError = null;
      generalError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;

    String? tempEmailError;
    String? tempPasswordError;

    /// VALIDASI EMAIL
    if (email.isEmpty) {
      tempEmailError = "Email tidak boleh kosong";
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      tempEmailError = "Format email tidak valid";
    }

    /// VALIDASI PASSWORD
    if (password.isEmpty) {
      tempPasswordError = "Kata sandi tidak boleh kosong";
    }

    /// update UI SEKALI (biar semua error muncul)
    setState(() {
      emailError = tempEmailError;
      passwordError = tempPasswordError;
    });

    /// stop kalau ada error
    if (tempEmailError != null || tempPasswordError != null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final token = await RecaptchaService.getToken()
        .timeout(const Duration(seconds: 10))
        .catchError((e) {
          print("reCAPTCHA error: $e");
          return null;
        });
      if (token == null) {
        setState(() {
          isLoading = false;
          generalError = "Gagal verifikasi reCAPTCHA";
        });
        return;
      }
      final response = await http.post(
        Uri.parse('https://underwear-yeast-aching.ngrok-free.dev/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'recaptcha_token': token,
        }),
      );

      print(response.statusCode);
      print(response.body);

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(
          'token',
          data['token'],
        );

        await prefs.setString(
          'name',
          data['user']['name'],
        );

        await prefs.setString(
          'email',
          data['user']['email'],
        );

        if (data['user']['phone'] != null) {
          await prefs.setString('phone', data['user']['phone']);
        }
        await prefs.setInt('id', data['user']['id']);
        if (data['user']['profile_picture_url'] != null) {
          await prefs.setString('profile_picture_url', data['user']['profile_picture_url']);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
      }
      else if (response.statusCode == 401) {
        setState(() {
          generalError = data['message']; // "Email atau password salah"
        });
      } 
      else {
        setState(() {
          generalError = data['message'] ?? "Terjadi kesalahan server";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        generalError = "Tidak dapat terhubung ke server";
      });

      print(e);
    }
  }
  bool isObscure = true;

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  String? emailError;
  String? passwordError;
  String? generalError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APPBAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: Stack(
        children: [

          /// =========================
          /// MAIN CONTENT
          /// =========================
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center,

                children: [

                  const SizedBox(height: 30),

                  /// TITLE
                  const Text(
                    "Masuk",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// SUBTITLE
                  Text(
                    "Selamat datang! Lanjutkan untuk masuk",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// =========================
                  /// EMAIL
                  /// =========================
                  const Align(
                    alignment: Alignment.centerLeft,

                    child: Text(
                      "Email",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: emailController,
                    cursorColor:
                        const Color(0xFF5F6F52),

                    onChanged: (value) {
                      setState(() {
                        emailError = null;
                        generalError = null;
                      });
                    },

                    decoration: InputDecoration(
                      hintText: "nama@contoh.com",

                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),

                      errorText: emailError,

                      filled: true,
                      fillColor:
                          const Color(0xFFFEFAE0),

                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),

                      /// BORDER NORMAL
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),

                        borderSide:
                            const BorderSide(
                          color: Color(0xFFE7DFC7),
                          width: 1,
                        ),
                      ),

                      /// BORDER FOCUS
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),

                        borderSide:
                            const BorderSide(
                          color: Color(0xFF5F6F52),
                          width: 1.6,
                        ),
                      ),

                      /// BORDER ERROR
                      errorBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),

                        borderSide:
                            const BorderSide(
                          color: Color(0xFFE57373),
                          width: 1.3,
                        ),
                      ),

                      focusedErrorBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),

                        borderSide:
                            const BorderSide(
                          color: Color(0xFFE57373),
                          width: 1.5,
                        ),
                      ),

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// =========================
                  /// PASSWORD
                  /// =========================
                  const Align(
                    alignment: Alignment.centerLeft,

                    child: Text(
                      "Kata Sandi",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: passwordController,

                    obscureText: isObscure,
                    obscuringCharacter: '•',

                    cursorColor:
                        const Color(0xFF5F6F52),

                    onChanged: (value) {
                      setState(() {
                        passwordError = null;
                        generalError = null;
                      });
                    },

                    decoration: InputDecoration(
                      hintText: "********",

                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),

                      errorText: passwordError,

                      filled: true,
                      fillColor:
                          const Color(0xFFFEFAE0),

                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),

                      /// BORDER NORMAL
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),

                        borderSide:
                            const BorderSide(
                          color: Color(0xFFE7DFC7),
                          width: 1,
                        ),
                      ),

                      /// BORDER FOCUS
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),

                        borderSide:
                            const BorderSide(
                          color: Color(0xFF5F6F52),
                          width: 1.6,
                        ),
                      ),

                      /// BORDER ERROR
                      errorBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),

                        borderSide:
                            const BorderSide(
                          color: Color(0xFFE57373),
                          width: 1.3,
                        ),
                      ),

                      focusedErrorBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),

                        borderSide:
                            const BorderSide(
                          color: Color(0xFFE57373),
                          width: 1.5,
                        ),
                      ),

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      suffixIcon: IconButton(
                        splashRadius: 20,

                        icon: Icon(
                          isObscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,

                          color: Colors.grey.shade600,
                        ),

                        onPressed: () {
                          setState(() {
                            isObscure = !isObscure;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// LUPA PASSWORD
                  Align(
                    alignment: Alignment.centerRight,

                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) =>
                                const ForgotPasswordPage(),
                          ),
                        );
                      },

                      child: const Text(
                        "Lupa Kata Sandi?",

                        style: TextStyle(
                          color: Color(0xFFB99470),
                          fontWeight: FontWeight.bold,

                          decoration:
                              TextDecoration.underline,

                          decorationColor:
                              Color(0xFFB99470),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// =========================
                  /// LOGIN BUTTON
                  /// =========================
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF5F6F52),

                        elevation: 0,

                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 17,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),

                      child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Masuk",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// =========================
                  /// REGISTER
                  /// =========================
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      const Text(
                        "Belum punya akun?",
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) =>
                                  const SignUpPage(),
                            ),
                          );
                        },

                        child: const Text(
                          "Daftar",

                          style: TextStyle(
                            color: Color(0xFFB99470),
                            fontWeight: FontWeight.bold,

                            decoration:
                                TextDecoration.underline,

                            decorationColor:
                                Color(0xFFB99470),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          /// =========================
          /// ERROR POPUP
          /// =========================
          AnimatedPositioned(
            duration:
                const Duration(milliseconds: 450),

            curve: Curves.easeInOut,

            top: generalError != null
                ? 10
                : -120,

            left: 16,
            right: 16,

            child: SafeArea(
              child: AnimatedOpacity(
                duration:
                    const Duration(milliseconds: 350),

                opacity:
                    generalError != null ? 1 : 0,

                child: Material(
                  color: Colors.transparent,

                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373),

                      borderRadius:
                          BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(
                            0.12,
                          ),

                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            generalError ?? "",

                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              generalError = null;
                            });
                          },

                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// =========================
          /// LOGO BAWAH
          /// =========================
          Align(
            alignment: Alignment.bottomCenter,

            child: Padding(
              padding:
                  const EdgeInsets.only(bottom: 20),

              child: Image.asset(
                'assets/logo/logo_restify.png',
                width: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }
}