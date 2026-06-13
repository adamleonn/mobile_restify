import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState
    extends State<EditProfilePage> {

  final _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      nameController =
          TextEditingController();

  final TextEditingController
    phoneController =
        TextEditingController();

  final TextEditingController
      emailController =
          TextEditingController();

  bool isLoading = false;
  String? profilePictureUrl;
  String? token;
  int? userId;

  File? selectedImage;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      userId = prefs.getInt('id');
      setState(() {
        nameController.text = prefs.getString('name') ?? '';
        emailController.text = prefs.getString('email') ?? '';
        phoneController.text = prefs.getString('phone') ?? '';
        profilePictureUrl = prefs.getString('profile_picture_url');
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });

      await uploadProfilePicture();
    }
  }

  Future<void> uploadProfilePicture() async {
    if (selectedImage == null || token == null) return;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://pelt-womanlike-popular.ngrok-free.dev/api/user/upload-profile',
        ),
      );

      request.headers['Authorization'] =
          'Bearer $token';

      request.headers['Accept'] =
          'application/json';

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          selectedImage!.path,
        ),
      );

      final response = await request.send();

      final responseBody =
          await response.stream.bytesToString();

      print(response.statusCode);
      print(responseBody);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        setState(() {
          profilePictureUrl =
              data['image_url'];
        });

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          'profile_picture_url',
          data['image_url'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Foto profile berhasil diperbarui",
              ),
            ),
          );
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateProfile() async {
    if (token == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://pelt-womanlike-popular.ngrok-free.dev/api/user/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', nameController.text.trim());
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('phone', phoneController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile berhasil diperbarui"),
              backgroundColor: Color(0xFF5F6F52),
            ),
          );
          Navigator.pop(context); // Kembali ke halaman profile
        }
      } else {
        final errorMessage = data['message'] ?? "Gagal memperbarui profile";
        showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackBar("Tidak dapat terhubung ke server");
    }
  }

  void showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE57373),
      ),
    );
  }

  OutlineInputBorder fieldBorder({
    Color color = Colors.transparent,
    double width = 1,
  }) {

    return OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(18),

      borderSide: BorderSide(
        color: color,
        width: width,
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
        scrolledUnderElevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),

        title: const Text(
          "Edit Profile",

          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),

        centerTitle: false,
      ),

      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,

          child: Padding(
            padding:
                const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// =========================
                /// PROFILE PHOTO
                /// =========================
                Center(
                  child: Stack(
                    children: [

                      Container(
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(
                                      0.06),

                              blurRadius: 10,

                              offset:
                                  const Offset(
                                0,
                                4,
                              ),
                            ),
                          ],
                        ),

                        child: CircleAvatar(
                          radius: 52,

                          backgroundColor:
                              const Color(0xFF5F6F52),

                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : profilePictureUrl != null
                                  ? NetworkImage(profilePictureUrl!)
                                  : null,

                          child: profilePictureUrl == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 50,
                                )
                              : null,
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,

                        child: GestureDetector(
                          onTap: pickImage,

                          child: Container(
                            padding:
                                const EdgeInsets
                                    .all(9),

                            decoration:
                                BoxDecoration(
                              color: const Color(
                                  0xFF5F6F52),

                              shape:
                                  BoxShape.circle,

                              border:
                                  Border.all(
                                color:
                                    Colors.white,
                                width: 3,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors
                                      .black
                                      .withOpacity(
                                          0.08),

                                  blurRadius: 6,

                                  offset:
                                      const Offset(
                                    0,
                                    2,
                                  ),
                                ),
                              ],
                            ),

                            child: const Icon(
                              Icons
                                  .camera_alt_rounded,

                              color:
                                  Colors.white,

                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 42),

                /// =========================
                /// NAME
                /// =========================
                const Text(
                  "Nama",

                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      nameController,

                  keyboardType:
                      TextInputType.name,

                  cursorColor:
                      const Color(
                          0xFF5F6F52),

                  validator: (value) {

                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {

                      return "Nama wajib diisi";
                    }

                    final nameRegex =
                        RegExp(
                      r"^[a-zA-Z\s.\'’-]+$",
                    );

                    if (!nameRegex
                        .hasMatch(value)) {

                      return "Nama hanya boleh huruf";
                    }

                    if (value
                            .trim()
                            .length <
                        3) {

                      return "Nama minimal 3 karakter";
                    }

                    if (value
                            .trim()
                            .length >
                        50) {

                      return "Nama terlalu panjang";
                    }

                    return null;
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        "Masukkan nama",

                    filled: true,

                    fillColor:
                        const Color(
                            0xFFFEFAE0),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),

                    enabledBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE7DFC7),
                    ),

                    focusedBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFF5F6F52),

                      width: 1.6,
                    ),

                    errorBorder:
                        fieldBorder(
                      color:
                          Colors.red,
                    ),

                    focusedErrorBorder:
                        fieldBorder(
                      color:
                          Colors.red,

                      width: 1.6,
                    ),

                    border:
                        fieldBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                /// =========================
                /// EMAIL
                /// =========================
                const Text(
                  "Email",

                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      emailController,

                  keyboardType:
                      TextInputType
                          .emailAddress,

                  cursorColor:
                      const Color(
                          0xFF5F6F52),

                  validator: (value) {

                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {

                      return "Email wajib diisi";
                    }

                    final emailRegex =
                        RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );

                    if (!emailRegex
                        .hasMatch(value)) {

                      return "Format email tidak valid";
                    }

                    return null;
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        "Masukkan email",

                    filled: true,

                    fillColor:
                        const Color(
                            0xFFFEFAE0),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),

                    enabledBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFFE7DFC7),
                    ),

                    focusedBorder:
                        fieldBorder(
                      color:
                          const Color(
                              0xFF5F6F52),

                      width: 1.6,
                    ),

                    errorBorder:
                        fieldBorder(
                      color:
                          Colors.red,
                    ),

                    focusedErrorBorder:
                        fieldBorder(
                      color:
                          Colors.red,

                      width: 1.6,
                    ),

                    border:
                        fieldBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                /// =========================
                /// PHONE
                /// =========================
                const Text(
                  "Nomor Telepon",

                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: phoneController,

                  keyboardType: TextInputType.phone,

                  cursorColor:
                      const Color(0xFF5F6F52),

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {

                      return "Nomor telepon wajib diisi";
                    }

                    final cleanedPhone =
                        value.replaceAll(" ", "");

                    final phoneRegex =
                        RegExp(r'^[0-9]+$');

                    if (!phoneRegex
                        .hasMatch(cleanedPhone)) {

                      return "Nomor telepon hanya boleh angka";
                    }

                    if (cleanedPhone.length < 10) {

                      return "Nomor telepon terlalu pendek";
                    }

                    if (cleanedPhone.length > 15) {

                      return "Nomor telepon terlalu panjang";
                    }

                    return null;
                  },

                  decoration: InputDecoration(
                    hintText:
                        "Masukkan nomor telepon",

                    filled: true,

                    fillColor:
                        const Color(0xFFFEFAE0),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),

                    enabledBorder:
                        fieldBorder(
                      color:
                          const Color(0xFFE7DFC7),
                    ),

                    focusedBorder:
                        fieldBorder(
                      color:
                          const Color(0xFF5F6F52),

                      width: 1.6,
                    ),

                    errorBorder:
                        fieldBorder(
                      color: Colors.red,
                    ),

                    focusedErrorBorder:
                        fieldBorder(
                      color: Colors.red,

                      width: 1.6,
                    ),

                    border: fieldBorder(),
                  ),
                ),

                const Spacer(),

                /// =========================
                /// SAVE BUTTON
                /// =========================
                GestureDetector(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      updateProfile();
                    }
                  },

                  child: Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 18,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                              0xFF5F6F52),

                      borderRadius:
                          BorderRadius
                              .circular(
                                  18),

                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(
                                      0xFF5F6F52)
                                  .withOpacity(
                                      0.18),

                          blurRadius: 10,

                          offset:
                              const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),

                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [

                        Icon(
                          Icons.save_rounded,
                          color:
                              Colors.white,
                          size: 22,
                        ),

                        SizedBox(
                          width: 10,
                        ),

                        Text(
                          "Simpan Perubahan",

                          style:
                              TextStyle(
                            color:
                                Colors.white,

                            fontSize: 16,

                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5F6F52),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();

    super.dispose();
  }
}