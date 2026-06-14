import 'package:flutter/material.dart';
import 'package:restify/login_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'recaptcha_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() =>
      _SignUpPageState();
}

class _SignUpPageState
    extends State<SignUpPage> {

  bool isPasswordObscure = true;
  bool isConfirmPasswordObscure = true;
  bool isLoading = false;

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController
      confirmPasswordController =
      TextEditingController();

  final TextEditingController
      phoneController =
      TextEditingController();

  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? generalError;
  String? phoneError;
  
  /// VALIDASI NAMA
  bool isValidName(String name) {

    return RegExp(
      r"^[a-zA-Z\s.\'’-]+$",
    ).hasMatch(name);
  }

  /// VALIDASI EMAIL
  bool isValidEmail(String email) {
    return RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    ).hasMatch(email);
  }

  /// VALIDASI PASSWORD
  bool isValidPassword(String password) {
    return RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
    ).hasMatch(password);
  }

  /// VALIDASI NOMOR TELEPON
  bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,15}$')
        .hasMatch(phone);
  }

  /// BORDER FIELD
  OutlineInputBorder fieldBorder({
    Color color = Colors.transparent,
  }) {

    return OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(16),

      borderSide: BorderSide(
        color: color,
        width: 1.4,
      ),
    );
  }

  Future<void> register() async {
    setState(() {
      isLoading = true;
      generalError = null;
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
        Uri.parse('https://underwear-yeast-aching.ngrok-free.dev/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'password': passwordController.text,
          'password_confirmation':
              confirmPasswordController.text,
          'recaptcha_token': token,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
        );
      } else {

        if (data['errors'] != null) {

          final errors = data['errors'];

          setState(() {
            nameError =
                errors['name']?.first;

            emailError =
                errors['email']?.first;

            phoneError =
                errors['phone']?.first;

            passwordError =
                errors['password']?.first;

            generalError =
                data['message'];
          });

        } else {

          setState(() {
            generalError =
                data['message'] ??
                "Pendaftaran gagal";
          });
        }
      }
    } catch (e) {

      setState(() {
        isLoading = false;
        generalError =
            "Tidak dapat terhubung ke server";
      });

      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: Stack(
        children: [

          /// =========================
          /// CONTENT
          /// =========================
          SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const SizedBox(height: 24),

                /// TITLE
                const Center(
                  child: Text(
                    "Daftar",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                /// SUBTITLE
                const Center(
                  child: Text(
                    "Buat akun baru untuk mulai menggunakan Restify",

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                /// =========================
                /// NAMA
                /// =========================
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    "Nama",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      nameController,

                  onChanged: (_) {
                    setState(() {
                      nameError = null;
                      generalError = null;
                    });
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        "Masukkan nama lengkap",

                    hintStyle: TextStyle(
                      color: Colors
                          .grey.shade500,
                      fontSize: 14,
                    ),

                    errorText:
                        nameError,

                    filled: true,

                    fillColor:
                        const Color(
                            0xFFFEFAE0),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    enabledBorder:
                        fieldBorder(),

                    focusedBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFF5F6F52),
                    ),

                    errorBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE57373),
                    ),

                    focusedErrorBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE57373),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// =========================
                /// NOMOR TELEPON
                /// =========================
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    "Nomor Telepon",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: phoneController,

                  keyboardType: TextInputType.phone,

                  onChanged: (_) {
                    setState(() {
                      phoneError = null;
                      generalError = null;
                    });
                  },

                  decoration: InputDecoration(
                    hintText: "08xxxxxxxxxx",

                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),

                    errorText: phoneError,

                    filled: true,

                    fillColor: const Color(0xFFFEFAE0),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    enabledBorder: fieldBorder(),

                    focusedBorder: fieldBorder(
                      color: const Color(0xFF5F6F52),
                    ),

                    errorBorder: fieldBorder(
                      color: const Color(0xFFE57373),
                    ),

                    focusedErrorBorder: fieldBorder(
                      color: const Color(0xFFE57373),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// =========================
                /// EMAIL
                /// =========================
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    "Email",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      emailController,

                  keyboardType:
                      TextInputType
                          .emailAddress,

                  onChanged: (_) {
                    setState(() {
                      emailError = null;
                      generalError = null;
                    });
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        "nama@contoh.com",

                    hintStyle: TextStyle(
                      color: Colors
                          .grey.shade500,
                      fontSize: 14,
                    ),

                    errorText:
                        emailError,

                    filled: true,

                    fillColor:
                        const Color(
                            0xFFFEFAE0),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    enabledBorder:
                        fieldBorder(),

                    focusedBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFF5F6F52),
                    ),

                    errorBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE57373),
                    ),

                    focusedErrorBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE57373),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// =========================
                /// PASSWORD
                /// =========================
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    "Kata Sandi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      passwordController,

                  obscureText:
                      isPasswordObscure,

                  obscuringCharacter:
                      '•',

                  onChanged: (_) {
                    setState(() {
                      passwordError = null;
                      generalError = null;
                    });
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        "Masukkan kata sandi",

                    hintStyle: TextStyle(
                      color: Colors
                          .grey.shade500,
                      fontSize: 14,
                    ),

                    errorText:
                        passwordError,

                    filled: true,

                    fillColor:
                        const Color(
                            0xFFFEFAE0),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    enabledBorder:
                        fieldBorder(),

                    focusedBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFF5F6F52),
                    ),

                    errorBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE57373),
                    ),

                    focusedErrorBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE57373),
                    ),

                    suffixIcon:
                        IconButton(
                      onPressed: () {

                        setState(() {
                          isPasswordObscure =
                              !isPasswordObscure;
                        });
                      },

                      icon: Icon(
                        isPasswordObscure
                            ? Icons
                                .visibility_off_rounded
                            : Icons
                                .visibility_rounded,

                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "    Minimal 8 karakter, mengandung huruf dan angka.",

                  style: TextStyle(
                    fontSize: 11.5,
                    color:
                        Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                /// =========================
                /// KONFIRMASI PASSWORD
                /// =========================
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    "Konfirmasi Kata Sandi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      confirmPasswordController,

                  obscureText:
                      isConfirmPasswordObscure,

                  obscuringCharacter:
                      '•',

                  onChanged: (_) {
                    setState(() {
                      confirmPasswordError =
                          null;

                      generalError = null;
                    });
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        "Konfirmasi kata sandi",

                    hintStyle: TextStyle(
                      color: Colors
                          .grey.shade500,
                      fontSize: 14,
                    ),

                    errorText:
                        confirmPasswordError,

                    filled: true,

                    fillColor:
                        const Color(
                            0xFFFEFAE0),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    enabledBorder:
                        fieldBorder(),

                    focusedBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFF5F6F52),
                    ),

                    errorBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE57373),
                    ),

                    focusedErrorBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE57373),
                    ),

                    suffixIcon:
                        IconButton(
                      onPressed: () {

                        setState(() {
                          isConfirmPasswordObscure =
                              !isConfirmPasswordObscure;
                        });
                      },

                      icon: Icon(
                        isConfirmPasswordObscure
                            ? Icons
                                .visibility_off_rounded
                            : Icons
                                .visibility_rounded,

                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                /// =========================
                /// BUTTON DAFTAR
                /// =========================
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: isLoading 
                    ? null : () {

                      setState(() {

                        nameError = null;
                        phoneError = null;
                        emailError = null;
                        passwordError = null;
                        confirmPasswordError = null;

                        generalError = null;

                        final name =
                            nameController
                                .text
                                .trim();

                        final phone =
                          phoneController.text.trim();

                        final email =
                            emailController
                                .text
                                .trim();

                        final password =
                            passwordController
                                .text;

                        final confirmPassword =
                            confirmPasswordController
                                .text;

                        /// VALIDASI NAMA
                        if (name.isEmpty) {

                          nameError =
                              "Nama tidak boleh kosong";

                        } else if (name.length < 3) {

                          nameError =
                              "Nama minimal 3 karakter";

                        } else if (!isValidName(name)) {

                          nameError =
                              "Nama hanya boleh huruf";
                        }

                        /// VALIDASI NOMOR TELEPON
                        if (phone.isEmpty) {

                          phoneError =
                              "Nomor telepon tidak boleh kosong";

                        } else if (!isValidPhone(phone)) {

                          phoneError =
                              "Nomor telepon tidak valid";
                        }

                        /// VALIDASI EMAIL
                        if (email.isEmpty) {

                          emailError =
                              "Email tidak boleh kosong";

                        } else if (!isValidEmail(
                          email,
                        )) {

                          emailError =
                              "Format email tidak valid";
                        }

                        /// VALIDASI PASSWORD
                        if (password.isEmpty) {

                          passwordError =
                              "Kata sandi tidak boleh kosong";

                        } else if (!isValidPassword(
                          password,
                        )) {

                          passwordError =
                              "Kata sandi harus mengandung huruf dan angka.";
                        }

                        /// VALIDASI KONFIRMASI
                        if (confirmPassword
                            .isEmpty) {

                          confirmPasswordError =
                              "Konfirmasi kata sandi wajib diisi";

                        } else if (confirmPassword !=
                            password) {

                          confirmPasswordError =
                              "Kata sandi tidak sama";
                        }
                      });
                      /// DUMMY REGISTER
                      if (nameError ==
                              null &&
                          phoneError == 
                              null &&
                          emailError ==
                              null &&
                          passwordError ==
                              null &&
                          confirmPasswordError ==
                              null) {

                          register();
                        }
                    },

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                              0xFF5F6F52),

                      elevation: 0,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 15,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    16),
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
                          "Daftar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
                ),

                const SizedBox(height: 18),

                /// =========================
                /// LOGIN LINK
                /// =========================
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [

                    const Text(
                      "Sudah punya akun?",
                    ),

                    TextButton(
                      onPressed: () {

                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginPage(),
                          ),
                        );
                      },

                      child: const Text(
                        "Masuk",

                        style: TextStyle(
                          color:
                              Color(0xFFB99470),

                          fontWeight:
                              FontWeight.bold,

                          decoration:
                              TextDecoration
                                  .underline,

                          decorationColor:
                              Color(0xFFB99470),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),

          /// =========================
          /// TOP ERROR POPUP
          /// =========================
          AnimatedPositioned(
            duration: const Duration(
              milliseconds: 400,
            ),

            curve: Curves.easeInOut,

            top: generalError != null
                ? 10
                : -120,

            left: 16,
            right: 16,

            child: SafeArea(
              child: AnimatedOpacity(
                duration:
                    const Duration(
                  milliseconds: 300,
                ),

                opacity:
                    generalError != null
                        ? 1
                        : 0,

                child: Material(
                  color:
                      Colors.transparent,

                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                              0xFFE57373),

                      borderRadius:
                          BorderRadius
                              .circular(
                                  50),

                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withOpacity(
                                  0.12),

                          blurRadius: 10,

                          offset:
                              const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        const Icon(
                          Icons
                              .error_rounded,

                          color:
                              Colors.white,
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Text(
                            generalError ?? "",

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,

                              fontWeight:
                                  FontWeight
                                      .w500,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {

                            setState(() {
                              generalError =
                                  null;
                            });
                          },

                          child: const Icon(
                            Icons
                                .close_rounded,

                            color:
                                Colors.white,
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
            alignment:
                Alignment.bottomCenter,

            child: Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 20,
              ),

              child: Opacity(
                opacity: 0.9,

                child: Image.asset(
                  'assets/logo/logo_restify.png',
                  width: 100,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}