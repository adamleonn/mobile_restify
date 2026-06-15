import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _baseUrl =
          'https://pelt-womanlike-popular.ngrok-free.dev'; //punya Nada
          
          // punya Adam'https://underwear-yeast-aching.ngrok-free.dev';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool isResetMode = false;
  bool isPasswordObscure = true;
  bool isConfirmPasswordObscure = true;
  bool isErrorMessage = false;

  String? emailError;
  String? tokenError;
  String? passwordError;
  String? confirmPasswordError;
  String? generalMessage;

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(password);
  }

  OutlineInputBorder fieldBorder({Color color = const Color(0xFFE7DFC7)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }

  Map<String, String> get requestHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<void> forgotPassword() async {
    setState(() {
      isLoading = true;
      generalMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/forgot-password'),
        headers: requestHeaders,
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          isErrorMessage = false;
          isResetMode = true;
          tokenController.text = (data['token'] ?? '').toString();
          generalMessage =
              "Token berhasil dibuat. Silakan buat kata sandi baru.";
        });
      } else {
        setState(() {
          isErrorMessage = true;
          generalMessage = data['message'] ?? "Terjadi kesalahan";
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isErrorMessage = true;
        generalMessage = "Tidak dapat terhubung ke server";
      });
    }
  }

  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
      generalMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/reset-password'),
        headers: requestHeaders,
        body: jsonEncode({
          'email': emailController.text.trim(),
          'token': tokenController.text.trim(),
          'password': passwordController.text,
          'password_confirmation': confirmPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          isErrorMessage = false;
          generalMessage = data['message'] ?? "Kata sandi berhasil direset";
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;

        setState(() {
          isErrorMessage = true;
          tokenError = errors?['token']?.first;
          passwordError = errors?['password']?.first;
          confirmPasswordError = errors?['password_confirmation']?.first;
          generalMessage = data['message'] ?? "Gagal mereset kata sandi";
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isErrorMessage = true;
        generalMessage = "Tidak dapat terhubung ke server";
      });
    }
  }

  void validateForgotPassword() {
    setState(() {
      emailError = null;
      generalMessage = null;
      isErrorMessage = false;

      final email = emailController.text.trim();
      if (email.isEmpty) {
        emailError = "Email tidak boleh kosong";
      } else if (!isValidEmail(email)) {
        emailError = "Format email tidak valid";
      }
    });

    if (emailError == null) forgotPassword();
  }

  void validateResetPassword() {
    setState(() {
      tokenError = null;
      passwordError = null;
      confirmPasswordError = null;
      generalMessage = null;
      isErrorMessage = false;

      final token = tokenController.text.trim();
      final password = passwordController.text;
      final confirmPassword = confirmPasswordController.text;

      if (token.isEmpty) {
        tokenError = "Token tidak boleh kosong";
      }

      if (password.isEmpty) {
        passwordError = "Kata sandi tidak boleh kosong";
      } else if (!isValidPassword(password)) {
        passwordError =
            "Minimal 8 karakter, mengandung huruf besar, huruf kecil, dan angka";
      }

      if (confirmPassword.isEmpty) {
        confirmPasswordError = "Konfirmasi kata sandi tidak boleh kosong";
      } else if (confirmPassword != password) {
        confirmPasswordError = "Konfirmasi kata sandi tidak cocok";
      }
    });

    if (tokenError == null &&
        passwordError == null &&
        confirmPasswordError == null) {
      resetPassword();
    }
  }

  Widget inputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        errorText: errorText,
        filled: true,
        fillColor: const Color(0xFFFEFAE0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: fieldBorder(),
        focusedBorder: fieldBorder(color: const Color(0xFF5F6F52)),
        errorBorder: fieldBorder(color: const Color(0xFFE57373)),
        focusedErrorBorder: fieldBorder(color: const Color(0xFFE57373)),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5F6F52),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    isResetMode ? "Reset Kata Sandi" : "Lupa Kata Sandi",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isResetMode
                        ? "Masukkan token dan kata sandi baru untuk akun Anda."
                        : "Masukkan email yang terdaftar untuk membuat token reset kata sandi.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  inputLabel("Email"),
                  const SizedBox(height: 8),
                  textField(
                    controller: emailController,
                    hintText: "nama@contoh.com",
                    errorText: emailError,
                    readOnly: isResetMode,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      setState(() {
                        emailError = null;
                        generalMessage = null;
                        isErrorMessage = false;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (isResetMode) ...[
                    inputLabel("Token Reset"),
                    const SizedBox(height: 8),
                    textField(
                      controller: tokenController,
                      hintText: "Token dari server",
                      errorText: tokenError,
                      onChanged: (_) {
                        setState(() {
                          tokenError = null;
                          generalMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    inputLabel("Kata Sandi Baru"),
                    const SizedBox(height: 8),
                    textField(
                      controller: passwordController,
                      hintText: "Kata sandi baru",
                      errorText: passwordError,
                      obscureText: isPasswordObscure,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isPasswordObscure = !isPasswordObscure;
                          });
                        },
                        icon: Icon(
                          isPasswordObscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {
                          passwordError = null;
                          generalMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    inputLabel("Konfirmasi Kata Sandi"),
                    const SizedBox(height: 8),
                    textField(
                      controller: confirmPasswordController,
                      hintText: "Ulangi kata sandi baru",
                      errorText: confirmPasswordError,
                      obscureText: isConfirmPasswordObscure,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordObscure =
                                !isConfirmPasswordObscure;
                          });
                        },
                        icon: Icon(
                          isConfirmPasswordObscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {
                          confirmPasswordError = null;
                          generalMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    primaryButton(
                      label: "Reset Kata Sandi",
                      onPressed: validateResetPassword,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                isResetMode = false;
                                tokenController.clear();
                                passwordController.clear();
                                confirmPasswordController.clear();
                                tokenError = null;
                                passwordError = null;
                                confirmPasswordError = null;
                                generalMessage = null;
                              });
                            },
                      child: const Text(
                        "Gunakan email lain",
                        style: TextStyle(
                          color: Color(0xFFB99470),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    primaryButton(
                      label: "Buat Token Reset",
                      onPressed: validateForgotPassword,
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      "Kembali ke Login",
                      style: TextStyle(
                        color: Color(0xFFB99470),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFB99470),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              offset: generalMessage != null
                  ? const Offset(0, 0)
                  : const Offset(0, -2),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isErrorMessage
                          ? const Color(0xFFE94235)
                          : Colors.green,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isErrorMessage ? Icons.error : Icons.check,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            generalMessage ?? "",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              generalMessage = null;
                            });
                          },
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Image.asset('assets/logo/logo_restify.png', width: 100),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    tokenController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
