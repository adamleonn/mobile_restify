# Restify Mobile App

Aplikasi Restify Mobile adalah aplikasi reservasi hotel berbasis mobile yang dibangun menggunakan **Flutter (Dart)**. Aplikasi ini terintegrasi langsung dengan API Backend Laravel 12 (Restify API) untuk menawarkan pengalaman pemesanan kamar hotel yang mulus, dilengkapi dengan AI Chatbot, payment gateway, dan fitur unduh cetak bukti pembayaran PDF secara langsung.

Proyek ini dibuat untuk memenuhi bagian mobile dari **Artefak TUBES 1 Web & Mobile**.

---

## Fitur Utama Mobile

- **Autentikasi & Akun**: Register, Login, Lupa Password OTP (melalui webhook n8n), Edit Profil (Ganti nama, telepon, email, foto profil), dan Hapus Akun mandiri.
- **Pencarian & Reservasi**: Jelajahi daftar hotel, filter berdasarkan kota/rating, lihat detail kamar, dan buat pesanan kamar.
- **Pembayaran Midtrans**: Integrasi webview pembayaran Snap Midtrans Sandbox secara dinamis.
- **Unduh E-Receipt PDF**: Membuat dan mengunduh bukti reservasi berformat PDF berkualitas tinggi menggunakan package `pdf` & `printing`.
- **AI Chatbot (Gemini)**: Fitur rekomendasi wisata dan hotel pintar terintegrasi dengan Google Gemini AI (`gemini-2.5-flash`).
- **Sistem Ulasan (Rating & Review)**: Berikan bintang (1-5), tulis ulasan, dan **unggah foto ulasan** langsung melalui input kamera/galeri setelah proses checkout. Untuk mencegah spam rating, pengguna hanya dapat memiliki 1 ulasan per reservasi, dengan opsi untuk mengedit ulasan/rating yang telah dikirimkan kapan saja.

---

## Persyaratan Sistem (Prerequisites)

Sebelum menjalankan aplikasi, pastikan Anda telah menyiapkan:
1. **Flutter SDK** (Versi SDK Dart yang didukung: `^3.11.0`)
2. **Android Studio** / **VS Code** dengan ekstensi Flutter & Dart terpasang
3. **Emulator Android** / **iOS Simulator** atau perangkat fisik dengan USB Debugging aktif
4. **Backend Laravel yang sedang berjalan** (Lihat instruksi setup backend di repositori `restify-webFinal`)
5. **Ngrok** terinstal untuk tunneling API lokal.
6. **n8n** terinstal secara lokal untuk workflow reset password OTP.

---

## Langkah-Langkah Konfigurasi & Menjalankan Aplikasi (Untuk Dosen)

### Langkah 1: Kloning & Buka Project
Buka direktori project mobile di terminal Anda:
```bash
cd mobile_restify/restify_mobile
```

### Langkah 2: Jalankan ngrok untuk API Tunneling
Buka terminal baru di komputer Anda (jangan tutup server Laravel backend) dan jalankan:
```bash
ngrok http 8000
```
Salin URL Forwarding HTTPS yang dihasilkan (contoh: `https://xxxx-xxxx.ngrok-free.app`).

### Langkah 3: Konfigurasi API Endpoint & Gemini Key
Agar aplikasi mobile dapat berkomunikasi dengan backend Laravel lokal Anda, Anda **WAJIB** memperbarui file konfigurasi IP atau URL.

1. Buka file [**`lib/config.dart`**](file:///d:/mobile_restify/restify_mobile/lib/config.dart).
2. Ganti nilai `baseUrl` dengan URL ngrok yang Anda dapatkan di Langkah 2:
   ```dart
   static const String baseUrl = 'https://xxxx-xxxx.ngrok-free.app';
   ```
3. **Konfigurasi Gemini API Key**:
   Di file `lib/config.dart`, chatbot menggunakan model **Gemini 2.5 Flash**. Anda dapat memperbarui kunci API Google Gemini pada variabel `geminiApiKey`. Anda bisa mengembalikan string API Key Anda langsung di getter `geminiApiKey` (dari Google AI Studio) atau menyamarkannya dalam format Base64.
   ```dart
   static String get geminiApiKey {
     const String encodedKey = 'QVEuQWI4Uk42TDQzaEZGbnF3Z0lzekdQT3pOQUR0RzF5cFl6ZFpRMXNIRG53WWtvQXkzVFE=';
     return utf8.decode(base64.decode(encodedKey));
   }
   ```

### Langkah 4: Install Dependensi & Jalankan Aplikasi
1. Unduh dan pasang semua pustaka/package Flutter yang dideklarasikan di `pubspec.yaml`:
   ```bash
   flutter pub get
   ```
2. Pastikan emulator Anda sudah aktif atau perangkat fisik Anda terdeteksi dengan perintah:
   ```bash
   flutter devices
   ```
3. Jalankan aplikasi dalam mode debug:
   ```bash
   flutter run
   ```

---

## Detail Konfigurasi 4 Komponen Utama

### 1. Terowongan Ngrok (Tunneling)
- **Fungsi:** Menjembatani emulator/perangkat fisik dengan localhost computer yang menjalankan server backend Laravel (`port 8000`).
- **Otomatisasi:** Aplikasi mobile ini secara otomatis menyertakan header `'ngrok-skip-browser-warning': 'true'` pada semua request `GET` agar tidak terganggu oleh halaman sambutan (landing page) ngrok.

### 2. Google reCAPTCHA v3
- **Fungsi:** Mengamankan halaman login dan register dari spam bot.
- **Kunci Pengujian Bawaan Google (Out of the Box):**
  Untuk mempermudah pengujian tanpa proses setup yang rumit, aplikasi ini telah dikonfigurasi menggunakan kunci pengujian (test keys) resmi dari Google:
  - **Site Key (Frontend & Mobile):** `6Le_NQktAAAAACGSaQhC9_rMYdzrbIzw1ylEbLBW` (tertanam di `lib/recaptcha_service.dart`)
  - **Secret Key (Backend):** `6Le_NQktAAAAALvA_ZqWeLthqxdj7rvNtNQt2voF` (dikonfigurasi di file `.env` Laravel backend)
  *Sifat Kunci Pengujian:* Kunci bawaan Google ini **tidak membatasi domain**, sehingga langsung berfungsi secara otomatis untuk pengujian di `localhost`, `127.0.0.1`, emulator Android/iOS, maupun domain tunneling Ngrok (`*.ngrok-free.app`), asalkan komputer memiliki koneksi internet aktif. Pengecekan reCAPTCHA berjalan aktif secara nyata tanpa ada bypass program.
  
- > [!IMPORTANT]
  > **Cara Mengonfigurasi Kunci reCAPTCHA Kustom (Jika Diperlukan):**
  > Jika dosen atau Anda ingin menggunakan kunci API reCAPTCHA Anda sendiri untuk verifikasi penuh pada domain tertentu, ikuti langkah berikut:
  > 1. Buka [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin) dan buat tipe **reCAPTCHA v3**.
  > 2. Daftarkan domain yang diizinkan, misalnya: `localhost` dan subdomain ngrok Anda (contoh: `xxxx-xxxx.ngrok-free.app` atau gunakan wildcard `ngrok-free.app` / `ngrok-free.dev`).
  > 3. Salin **Site Key** dan **Secret Key** baru Anda.
  > 4. **Update di Backend Laravel:**
  >    Buka file `backend/.env` dan ubah variabel berikut:
  >    ```env
  >    RECAPTCHA_SECRET_KEY=isi_dengan_secret_key_baru_anda
  >    ```
  >    Lalu jalankan `php artisan config:clear` di terminal backend.
  > 5. **Update di Frontend Web Next.js:**
  >    Buka file `frontend/.env` dan ubah:
  >    ```env
  >    NEXT_PUBLIC_RECAPTCHA_SITE_KEY=isi_dengan_site_key_baru_anda
  >    ```
  > 6. **Update di Aplikasi Mobile (Flutter):**
  >    Buka berkas [**`lib/recaptcha_service.dart`**](file:///d:/mobile_restify/restify_mobile/lib/recaptcha_service.dart), lalu ganti Site Key bawaan (`6Le_NQktAAAAACGSaQhC9_rMYdzrbIzw1ylEbLBW`) pada baris 35 (fungsi JavaScript execute) dan baris 45 (URL script loader) dengan Site Key kustom Anda yang baru.

### 3. Payment Gateway Midtrans Sandbox
- **Fungsi:** Menyediakan simulasi pembayaran reservasi hotel secara real-time via WebView.
- **Sinkronisasi Status Pembayaran (PENTING):**
  Salin URL Forwarding ngrok Anda (misalnya: `https://xxxx-xxxx.ngrok-free.app`) dan daftarkan sebagai Webhook Notification URL di Dashboard Sandbox Midtrans Anda:
  `https://xxxx-xxxx.ngrok-free.app/api/midtrans/callback`.
  Hal ini diperlukan agar status pembayaran di aplikasi Flutter otomatis berubah dari `pending` ke `confirmed/paid` sesaat setelah pembayaran disimulasikan sukses di simulator Midtrans.

### 4. n8n Reset Password OTP Workflow
- **Fungsi:** Mengirim kode verifikasi OTP 6 digit ke email pengguna ketika mengklik "Lupa Kata Sandi".
- **Langkah Setup:**
  1. Jalankan n8n secara lokal (`npm install -g n8n` dan `npx n8n`).
  2. Impor berkas `Restify.json` di dashboard n8n lokal (`http://localhost:5678`).
  3. Konfigurasi kredensial SMTP Gmail (menggunakan App Password).
  4. Aktifkan workflow (Publish) dan update URL webhook di `AuthController.php` backend Laravel.

---

## Struktur Folder Penting (lib/)

```text
lib/
├── config.dart             # Konfigurasi URL API & API Key Gemini
├── main.dart               # Entrypoint aplikasi Flutter & inisialisasi route
├── pdf_service.dart        # Service pembuatan dokumen E-Receipt PDF premium
├── image_utils.dart        # Helper penanganan upload & kompresi foto
├── chatbot_page.dart       # Integrasi AI Chatbot (Gemini 2.5 Flash)
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

## Data Akun Pengujian
- **Akun Tamu (User / Customer)** (Dapat memesan kamar, mencoba chatbot, membayar via simulator Midtrans, rating, ulasan foto, unduh PDF receipt):
  - **Email**: `user@restify.com`
  - **Password**: `User1234`
- **Akun Resepsionis** (Untuk memproses check-in/out tamu):
  - **Email**: `receptionist.flores@gmail.com`
  - **Password**: `Recep1234`
- **Akun Admin** (Untuk mengelola hotel, kamar, user global):
  - **Email**: `admin@restify.com`
  - **Password**: `Admin1234`

---

*Selamat menguji! Restify Mobile v2.2.0*
