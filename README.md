# Mobile Restify

Ini adalah aplikasi mobile Flutter untuk Restify (Pemesanan Hotel) yang terintegrasi dengan Laravel Backend, Midtrans Payment Gateway, n8n Automation, dan Google Gemini AI.

---

## Persyaratan Sistem (Prerequisites)
Sebelum menjalankan aplikasi, pastikan Anda telah menyiapkan:
- **Flutter SDK** terpasang di komputer Anda.
- **Backend Laravel** berjalan di lokal (menggunakan `php artisan serve`).
- **PostgreSQL** berjalan dan database `restify` telah di-import.
- **Ngrok** terinstal (untuk menghubungkan emulator/perangkat fisik ke backend lokal).
- **n8n** terinstal secara lokal (untuk simulasi lupa kata sandi OTP).

---

## Panduan Cepat Menjalankan Aplikasi (Untuk Dosen / Penguji)

Untuk memudahkan penilaian, ikuti langkah-langkah terstruktur di bawah ini secara berurutan:

### Langkah 1: Jalankan Backend Laravel & Scheduler
1. Buka terminal di dalam folder backend web (`restify-webFinal/backend`).
2. Jalankan server Laravel:
   ```bash
   php artisan serve
   ```
   *(Server akan aktif di `http://127.0.0.1:8000`)*
3. Jalankan scheduler Laravel (untuk auto-cancel booking yang tidak dibayar dalam 15 menit):
   ```bash
   # Buka terminal baru di folder backend/
   php artisan schedule:work
   ```

### Langkah 2: Jalankan ngrok untuk API Tunneling
Buka terminal baru (jangan tutup terminal backend) dan ekspos port `8000` menggunakan ngrok:
```bash
ngrok http 8000
```
Salin URL Forwarding HTTPS yang dihasilkan (contoh: `https://xxxx-xxxx.ngrok-free.app`).

### Langkah 3: Perbarui URL API & Gemini Key di Flutter
1. Buka folder `mobile_restify/restify_mobile` di VS Code atau editor Anda.
2. Buka file [**`lib/config.dart`**](file:///d:/mobile_restify/restify_mobile/lib/config.dart).
3. Ganti nilai `baseUrl` dengan URL ngrok yang Anda salin pada Langkah 2:
   ```dart
   static const String baseUrl = 'https://xxxx-xxxx.ngrok-free.app';
   ```
4. **(Opsional) Konfigurasi Gemini API Key**:
   Di file `lib/config.dart`, chatbot menggunakan model **Gemini 2.5 Flash**. Anda dapat memperbarui kunci API Google Gemini pada variabel `geminiApiKey`. Anda bisa mengembalikan string API Key Anda langsung di getter `geminiApiKey` (dari Google AI Studio) atau menyamarkannya dalam format Base64.

### Langkah 4: Jalankan Aplikasi Flutter
Hubungkan emulator Android/iOS atau perangkat fisik, lalu buka terminal di folder `mobile_restify/restify_mobile` dan jalankan:
```bash
flutter pub get
flutter run
```

---

## Panduan Detail Konfigurasi 4 Komponen Utama

Aplikasi ini menggunakan integrasi layanan pihak ketiga agar memiliki fitur lengkap layaknya aplikasi produksi. Berikut adalah petunjuk konfigurasi masing-masing layanan:

### 1. Terowongan Ngrok (Ngrok Tunneling)
- **Mengapa ini diperlukan?** Emulator Android/iOS dan perangkat fisik tidak dapat mengakses `localhost:8000` komputer Anda secara langsung. Ngrok membuat terowongan HTTPS publik yang aman ke server Laravel lokal Anda.
- **Penanganan Otomatis:** Beberapa penyedia layanan tunneling seperti ngrok menampilkan halaman peringatan browser (landing page) saat diakses pertama kali. Aplikasi mobile Restify telah dikonfigurasi untuk menyertakan header `'ngrok-skip-browser-warning': 'true'` di setiap request `GET` secara otomatis, sehingga transmisi data berjalan lancar tanpa intervensi manual.

### 2. Google reCAPTCHA v3 (Proteksi Form Registrasi & Login)
- **Bagaimana cara kerjanya?** reCAPTCHA v3 berjalan di latar belakang untuk mendeteksi apakah interaksi berasal dari manusia atau bot saat pengguna mendaftar/masuk.
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

### 3. Payment Gateway Midtrans (Simulasi Pembayaran)
- **Bagaimana cara kerjanya?** Saat memesan kamar hotel, pengguna dapat membayar secara real-time via simulator Midtrans Snap (Virtual Account, kartu kredit simulasi, dll.).
- **Konfigurasi Backend:**
  Pastikan berkas `backend/.env` Anda sudah terisi dengan kredensial Sandbox Midtrans Anda (bisa didapatkan gratis di [Dashboard Sandbox Midtrans](https://dashboard.sandbox.midtrans.com/)):
  ```env
  MIDTRANS_SERVER_KEY=isi_dengan_server_key_sandbox_anda
  MIDTRANS_CLIENT_KEY=isi_dengan_client_key_sandbox_anda
  ```
- **Real-Time Webhook (PENTING untuk sinkronisasi status pesanan):**
  Agar status pembayaran otomatis berubah menjadi **Confirmed / Paid** di aplikasi mobile, daftarkan URL callback ngrok Anda ke dashboard Midtrans:
  1. Masuk ke Dashboard Midtrans Sandbox -> **Settings** -> **Configuration**.
  2. Isi kolom **Payment Notification URL** dengan:
     `https://xxxx-xxxx.ngrok-free.app/api/midtrans/callback` *(Ganti dengan subdomain ngrok Anda saat ini)*.
  3. Klik **Save**.

### 4. Alur OTP Lupa Kata Sandi (Integrasi n8n)
- **Bagaimana cara kerjanya?** Saat pengguna meminta reset kata sandi pada halaman lupa password, backend akan memicu workflow n8n untuk mengirimkan kode OTP 6-digit ke email target.
- **Setup n8n lokal:**
  1. Install n8n secara global di komputer Anda:
     ```bash
     npm install -g n8n
     npx n8n
     ```
  2. Buka dashboard n8n di `http://localhost:5678`.
  3. Buat workflow baru -> klik opsi **Import from file** -> pilih file `Restify.json` dari root proyek backend.
  4. Konfigurasikan node Email (SMTP) menggunakan SMTP Gmail Anda (gunakan [App Password Google](https://myaccount.google.com/apppasswords)).
  5. Klik **Publish** pada n8n untuk mengaktifkan workflow.
  6. Salin **Production URL Webhook** dari node Webhook n8n Anda.
  7. Perbarui URL Webhook pada method `forgotPassword` di berkas backend Laravel: `backend/app/Http/Controllers/AuthController.php`.

---

## Asisten AI Chatbot (Gemini 2.5 Flash)

Aplikasi Restify dilengkapi dengan asisten AI pintar yang merekomendasikan hotel secara interaktif berdasarkan database hotel saat ini:
- **Model AI:** Menggunakan Google Generative AI **`gemini-2.5-flash`** untuk respon cepat dan akurat.
- **Konfigurasi Kunci API:**
  API Key disamarkan demi keamanan rilis. Agar chatbot berfungsi penuh, Anda dapat memperbarui API Key di file `lib/config.dart`:
  ```dart
  static String get geminiApiKey {
    // Anda dapat mengganti nilai string base64 ini dengan API Key Anda yang di-encode ke Base64:
    const String encodedKey = 'QVEuQWI4Uk42TDQzaEZGbnF3Z0lzekdQT3pOQUR0RzF5cFl6ZFpRMXNIRG53WWtvQXkzVFE=';
    return utf8.decode(base64.decode(encodedKey));
    
    // Atau jika ingin langsung mengembalikan string biasa tanpa Base64:
    // return 'AIzaSy...'; // API Key Anda dari Google AI Studio
  }
  ```

---

## Data Akun Uji Coba Default
Dosen dapat menggunakan kredensial berikut untuk menguji berbagai peran di platform:
- **Akun Tamu (User / Customer)** (Dapat melakukan pencarian, favoritisasi, reservasi, pembayaran Midtrans, chatbot Gemini, unduh PDF, rating & ulasan):
  - **Email**: `user@restify.com`
  - **Password**: `User1234`
- **Akun Resepsionis** (Untuk memproses check-in/out tamu):
  - **Email**: `receptionist.flores@gmail.com`
  - **Password**: `Recep1234`
- **Akun Admin** (Untuk manajemen database hotel, kamar, user global):
  - **Email**: `admin@restify.com`
  - **Password**: `Admin1234`

---

## Changelog Terbaru

### v2.3.0 — Juni 2026 (Peningkatan UX, Fitur Keamanan, & Dukungan Multi-Kota)
- **Penyimpanan Kota Terpilih (City Persistence)**: Mengintegrasikan `SharedPreferences` pada halaman beranda (`home_page.dart`) agar kota pilihan pengguna tetap tersimpan ketika aplikasi dimuat ulang atau dibuka kembali.
- **Relokasi & Keamanan Fitur Hapus Akun**: Memindahkan tombol "Hapus Akun" dari halaman profil utama ke bagian bawah form edit profil (`edit_profile_page.dart`) untuk mencegah ketidaksengajaan klik. Menambahkan layout scrollable untuk menghindari layout overflow akibat munculnya keyboard virtual.
- **Visualisasi Status Kamar Maintenance**: Menampilkan status kamar pemeliharaan secara visual terproteksi (greyed-out), lencana merah "Sedang Maintenance", serta memblokir fungsi klik booking kamar tersebut dengan notifikasi pesan SnackBar.
- **Dukungan Multi-Kota Penuh**: Membuka batasan pengembangan kota Bali dan Yogyakarta pada deteksi kota sehingga pengguna dapat menelusuri hotel di wilayah tersebut serta berinteraksi secara penuh dengan Chatbot Gemini.
- **Fix Masalah Lifecycle Redirect**: Memperbaiki issue crash navigasi pada widget `IndexedStack` saat token otentikasi kedaluwarsa dengan membungkus rutinitas redirect dalam callback `addPostFrameCallback`.
- **Header Bypass Ngrok**: Menyertakan header `'ngrok-skip-browser-warning': 'true'` pada semua HTTP request autentikasi (login, register, profil) untuk menghindari kegagalan parser respons akibat halaman peringatan ngrok.

---

*Dibuat untuk TUBES Mobile — Restify v2.3.0*
