import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? name;
  String? email;
  String? phone;
  String? profilePictureUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        navigateToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('https://pelt-womanlike-popular.ngrok-free.dev/api/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['user'];

        setState(() {
          name = userData['name'];
          email = userData['email'];
          phone = userData['phone'];
          profilePictureUrl = userData['profile_picture_url'];
          isLoading = false;
        });

        // Simpan data terbaru ke local storage
        await prefs.setString('name', name ?? '');
        await prefs.setString('email', email ?? '');
        if (phone != null) {
          await prefs.setString('phone', phone!);
        }
        if (profilePictureUrl != null) {
          await prefs.setString('profile_picture_url', profilePictureUrl!);
        }
        await prefs.setInt('id', userData['id']);
      } else if (response.statusCode == 401) {
        navigateToLogin();
      } else {
        setState(() {
          isLoading = false;
        });
        showErrorSnackBar("Gagal mengambil data profil");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackBar("Tidak dapat terhubung ke server");
    }
  }

  Future<void> logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5F6F52),
          ),
        );
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        await http.post(
          Uri.parse('https://pelt-womanlike-popular.ngrok-free.dev/api/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      await prefs.clear();

      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading
      }
      navigateToLogin();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading
      }
      // Tetap bersihkan session lokal & logout jika request gagal
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      navigateToLogin();
    }
  }

  void navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5F6F52),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// =========================
                                /// HEADER
                                /// =========================
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'assets/logo/logo_restify.png',
                                      width: 200,
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      "Profile",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                /// PROFILE CARD
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    children: [
                                      Row(
                                        children: [
                                          /// AVATAR
                                          CircleAvatar(
                                            radius: 32,
                                            backgroundColor: const Color(0xFF5F6F52),
                                            backgroundImage: profilePictureUrl != null
                                                ? NetworkImage(profilePictureUrl!)
                                                : null,
                                            child: profilePictureUrl == null
                                                ? const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 32,
                                                  )
                                                : null,
                                          ),

                                          const SizedBox(width: 16),

                                          /// USER INFO
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name ?? "Guest",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                email ?? "-",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                phone ?? "Belum diatur",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      /// EDIT BUTTON
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const EditProfilePage(),
                                              ),
                                            ).then((_) {
                                              // Refresh data saat kembali dari halaman edit profile
                                              fetchProfile();
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.04),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.mode_edit_outline_rounded,
                                              size: 18,
                                              color: Color(0xFF5F6F52),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                /// SYARAT & KETENTUAN
                                InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    showTermsDialog(context);
                                  },
                                  child: profileMenu(
                                    icon: Icons.description_outlined,
                                    title: "Syarat & Ketentuan",
                                  ),
                                ),

                                const SizedBox(height: 16),

                                /// TENTANG RESTIFY
                                InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    showAboutAppDialog(context);
                                  },
                                  child: profileMenu(
                                    icon: Icons.info_outline_rounded,
                                    title: "Tentang Restify",
                                  ),
                                ),
                              ],
                            ),

                            /// =========================
                            /// LOGOUT BUTTON
                            /// =========================
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                showLogoutDialog(context);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE1E1),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFF0B4B4),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFE57373),
                                      size: 24,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Logout",
                                      style: TextStyle(
                                        color: Color(0xFFE57373),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
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
                  );
                },
              ),
      ),
    );
  }

  /// =========================
  /// LOGOUT DIALOG
  /// =========================
  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFCF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Apakah kamu yakin ingin keluar dari akun?",
            style: TextStyle(
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                /// BATAL
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFF1F1F1F),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Batal",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// KELUAR
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Tutup dialog
                      logout(); // Panggil logout API
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE57373),
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFFD85C5F),
                        width: 1,
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Keluar",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// =========================
  /// SYARAT & KETENTUAN DIALOG
  /// =========================
  void showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFCF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF5F6F52)),
              SizedBox(width: 10),
              Text(
                "Syarat & Ketentuan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat datang di Restify. Dengan menggunakan aplikasi kami, Anda menyetujui syarat & ketentuan berikut:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTermItem(
                    "1. Akun Pengguna",
                    "Pengguna wajib memberikan informasi yang benar, akurat, dan terbaru saat melakukan pendaftaran. Keamanan akun merupakan tanggung jawab pribadi pengguna.",
                  ),
                  _buildTermItem(
                    "2. Layanan Pemesanan",
                    "Restify memfasilitasi pemesanan kamar hotel secara online. Informasi ketersediaan kamar dan harga dapat berubah sewaktu-waktu sesuai kebijakan hotel mitra.",
                  ),
                  _buildTermItem(
                    "3. Pembayaran & Pembatalan",
                    "Semua transaksi pembayaran harus diselesaikan melalui metode pembayaran resmi yang tersedia di aplikasi. Kebijakan pembatalan pemesanan mengikuti aturan yang berlaku pada masing-masing hotel.",
                  ),
                  _buildTermItem(
                    "4. Kebijakan Privasi",
                    "Restify berkomitmen untuk melindungi data pribadi Anda. Penggunaan data Anda akan tunduk pada Kebijakan Privasi Restify.",
                  ),
                  _buildTermItem(
                    "5. Perubahan Ketentuan",
                    "Restify berhak memperbarui syarat dan ketentuan ini kapan saja untuk menyesuaikan dengan regulasi terbaru atau peningkatan layanan.",
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F6F52),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Saya Mengerti",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF5F6F52),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// TENTANG RESTIFY DIALOG
  /// =========================
  void showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFCF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Image.asset(
                  'assets/logo/logo_restify.png',
                  width: 160,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Restify App",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Color(0xFF5F6F52),
                  ),
                ),
                const Text(
                  "Versi 1.0.0",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Restify adalah aplikasi pemesanan penginapan dan hotel premium yang dirancang untuk mempermudah perjalanan Anda. Temukan berbagai pilihan akomodasi terbaik dengan harga bersaing, serta nikmati kemudahan transaksi dalam satu genggaman.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  "Dibuat untuk Tugas Kuliah",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "© 2026 Restify Team. All rights reserved.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F6F52),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Tutup",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// =========================
  /// PROFILE MENU
  /// =========================
  Widget profileMenu({
    required IconData icon,
    required String title,
    bool isRed = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isRed ? Colors.red.shade400 : const Color(0xFF5F6F52),
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isRed ? Colors.red.shade400 : Colors.black,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}