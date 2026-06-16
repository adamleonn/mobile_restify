import 'package:flutter/material.dart';
import 'package:restify/signup_page.dart';
import 'package:restify/login_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(), // dorong ke tengah

            // TITLE
            const Text(
              "Mulai Perjalanan Nyaman Anda Bersama Restify",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // SUBTEXT
            const Text(
              "Masuk atau daftar untuk menemukan\n tempat menginap terbaik sesuai kebutuhan Anda",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // BUTTON MASUK
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F6F52),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Masuk",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // BUTTON DAFTAR
            SizedBox(
              width: 250,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5F6F52)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Daftar",
                  style: TextStyle(
                    color: Color(0xFF5F6F52),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Image.asset(
                'assets/logo/logo_restify.png',
                width: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}