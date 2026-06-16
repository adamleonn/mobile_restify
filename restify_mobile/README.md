# Restify Mobile App

Aplikasi Restify Mobile adalah aplikasi reservasi hotel berbasis mobile yang dibangun menggunakan **Flutter (Dart)**. Aplikasi ini terintegrasi langsung dengan API Backend Laravel 12 (Restify API) untuk menawarkan pengalaman pemesanan kamar hotel yang mulus, dilengkapi dengan AI Chatbot, payment gateway, dan fitur unduh cetak bukti pembayaran PDF secara langsung.

Proyek ini dibuat untuk memenuhi bagian mobile dari **Artefak TUBES 1 Web & Mobile**.

---

## 🚀 Fitur Utama Mobile

- **Autentikasi & Akun**: Register, Login, Lupa Password OTP (melalui webhook n8n), Edit Profil (Ganti nama, telepon, email, foto profil), dan Hapus Akun mandiri.
- **Pencarian & Reservasi**: Jelajahi daftar hotel, filter berdasarkan kota/rating, lihat detail kamar, dan buat pesanan kamar.
- **Pembayaran Midtrans**: Integrasi webview pembayaran Snap Midtrans Sandbox secara dinamis.
- **Unduh E-Receipt PDF**: Membuat dan mengunduh bukti reservasi berformat PDF berkualitas tinggi menggunakan package `pdf` & `printing`.
- **AI Chatbot (Gemini)**: Fitur rekomendasi wisata dan hotel pintar terintegrasi dengan Google Gemini AI (`gemini-2.5-flash`).
- **Sistem Ulasan (Rating & Review)**: Berikan bintang (1-5), tulis ulasan, dan **unggah foto ulasan** langsung melalui input kamera/galeri setelah proses checkout.

---

## ⚙️ Persyaratan Sistem (Prerequisites)

Sebelum menjalankan aplikasi, pastikan Anda telah menyiapkan:
1. **Flutter SDK** (Versi SDK Dart yang didukung: `^3.11.0`)
2. **Android Studio** / **VS Code** dengan ekstensi Flutter & Dart terpasang
3. **Emulator Android** / **iOS Simulator** atau perangkat fisik dengan USB Debugging aktif
4. **Backend Laravel yang sedang berjalan** (Lihat instruksi setup backend di repositori `restify-webFinal`)

---

## 🛠️ Langkah-Langkah Konfigurasi & Menjalankan Aplikasi

### Langkah 1: Kloning & Buka Project
Buka direktori project mobile di terminal Anda:
```bash
cd mobile_restify/restify_mobile
```

### Langkah 2: Konfigurasi API Endpoint & Gemini Key
Agar aplikasi mobile dapat berkomunikasi dengan backend Laravel lokal Anda, Anda **WAJIB** memperbarui file konfigurasi IP atau URL.

1. Buka file [**`lib/config.dart`**](file:///d:/mobile_restify/restify_mobile/lib/config.dart).
2. Sesuaikan nilai `baseUrl` sesuai dengan lingkungan pengujian Anda:
   - **Jika menggunakan Emulator Android**: Gunakan IP khusus emulator untuk mengakses localhost komputer Anda:
     ```dart
     static const String baseUrl = 'http://10.0.2.2:8000';
     ```
   - **Jika menggunakan Device Fisik (HP)**: Gunakan IP lokal komputer Anda (pastikan HP dan komputer berada di jaringan Wi-Fi yang sama):
     ```dart
     static const String baseUrl = 'http://192.168.x.x:8000'; // Ganti dengan IP lokal Anda
     ```
   - **Jika menggunakan Ngrok (Direkomendasikan)**: Jika backend Anda di-expose menggunakan Ngrok:
     ```dart
     static const String baseUrl = 'https://your-subdomain.ngrok-free.app';
     ```
3. Sesuaikan `geminiApiKey` jika Anda memiliki API Key Gemini pribadi untuk AI Chatbot.

---

### Langkah 3: Install Dependensi (Packages)
Unduh dan pasang semua pustaka/package Flutter yang dideklarasikan di `pubspec.yaml`:
```bash
flutter pub get
```

---

### Langkah 4: Hubungkan Perangkat & Jalankan Aplikasi
1. Pastikan emulator Anda sudah aktif atau perangkat fisik Anda terdeteksi dengan perintah:
   ```bash
   flutter devices
   ```
2. Jalankan aplikasi dalam mode debug:
   ```bash
   flutter run
   ```

---

## 📁 Struktur Folder Penting (lib/)

```text
lib/
├── config.dart             # Konfigurasi URL API & API Key Gemini
├── main.dart               # Entrypoint aplikasi Flutter & inisialisasi route
├── pdf_service.dart        # Service pembuatan dokumen E-Receipt PDF premium
├── image_utils.dart        # Helper penanganan upload & kompresi foto
├── chatbot_page.dart       # Integrasi AI Chatbot (Gemini)
├── detail_booking_page.dart # Detail status pesanan & tombol cetak PDF / rating
├── detail_hotel_page.dart  # Informasi hotel, ulasan, kamar, & peta lokasi
├── booking_page.dart       # Form pemesanan kamar & checkout
├── edit_profile_page.dart  # Form ubah detail profil & foto
├── favorite_page.dart      # Daftar hotel yang disimpan/difavoritkan
├── forgot_pass_page.dart   # Halaman reset password menggunakan OTP n8n
├── home_page.dart          # Halaman utama dengan daftar rekomendasi hotel
├── list_hotel_page.dart    # Daftar hotel lengkap dengan pencarian & filter kota
├── login_page.dart         # Form masuk
├── signup_page.dart        # Form pendaftaran akun baru
├── profile_page.dart       # Tab profil, riwayat pesanan, logout, hapus akun
├── reservation_page.dart   # Riwayat reservasi (Tamu) & manajemen pesanan
└── midtrans_page.dart      # WebView untuk gerbang pembayaran Midtrans Snap
```

---

## 📝 Catatan Tambahan untuk Pengujian Dosen / Penguji
- **Akun Demo**: Anda dapat melakukan registrasi mandiri langsung dari aplikasi, atau menggunakan akun pengujian default:
  - **Email**: `user@restify.com`
  - **Password**: `User1234`
- **Pajak & Total**: PDF E-Receipt yang dibuat dari aplikasi mobile secara otomatis menghitung Pajak 10% dan menampilkan Grand Total dengan format mata uang Rupiah yang rapi (`Rp x.xxx.xxx`).
- **Ulasan Foto**: Saat memberikan rating setelah status checkout selesai, Anda dapat memilih foto dari galeri atau mengambil langsung dari kamera HP Anda.

---

*Selamat menguji! Restify Mobile v2.1.0*
