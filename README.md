# Mobile Restify

Ini adalah aplikasi mobile Flutter untuk Restify (Pemesanan Hotel).

## Persyaratan Sistem
- Flutter SDK terinstal di perangkat Anda.
- Laravel Backend berjalan di lokal (menggunakan `php artisan serve`).
- Akun dan aplikasi **ngrok** (digunakan untuk mengekspos API lokal agar bisa diakses dari emulator/perangkat seluler).

---

## Panduan Menjalankan Aplikasi Mobile untuk Penilaian (Dosen)

Karena aplikasi mobile ini memerlukan akses ke API dari backend Laravel yang berjalan di lokal Anda, kita harus menggunakan **ngrok** sebagai jembatan untuk menghubungkan perangkat mobile ke backend lokal. 

Berikut langkah-langkah detailnya:

### Langkah 1: Jalankan Backend Laravel
Pastikan Anda telah membuka dan menjalankan proyek web/backend Laravel (misalnya, folder `restify-webFinal`):
1. Buka terminal di dalam folder backend web tersebut.
2. Jalankan perintah berikut:
   ```bash
   php artisan serve
   ```
   *(Backend biasanya berjalan di `http://127.0.0.1:8000` atau `http://localhost:8000`)*

### Langkah 2: Jalankan ngrok
Buka terminal baru (jangan tutup terminal backend) dan jalankan ngrok untuk mengekspos port `8000`:
```bash
ngrok http 8000
```
Setelah berjalan, ngrok akan memberikan URL Forwarding (biasanya berakhiran `.ngrok-free.app` atau `.ngrok-free.dev`).
Contoh URL: `https://xxxxx.ngrok-free.dev`

### Langkah 3: Update URL ngrok di Aplikasi Mobile
Anda perlu mengganti URL API di kode mobile dengan URL ngrok yang baru saja Anda dapatkan.

1. Buka folder `restify_mobile` di VS Code atau Android Studio.
2. Lakukan **Search and Replace** (Pencarian dan Penggantian secara global) di seluruh file dalam folder `lib/`.
   - **Cari tulisan ini:** `https://underwear-yeast-aching.ngrok-free.dev`
   - **Ganti dengan:** *URL ngrok Anda yang baru* (contoh: `https://xxxxx.ngrok-free.dev`)
3. Simpan semua file yang mengalami perubahan (di VS Code bisa menggunakan File -> Save All).

### Langkah 4: Jalankan Aplikasi Mobile
Setelah URL API diperbarui, Anda dapat menjalankan aplikasi di emulator Android/iOS atau perangkat fisik.

Buka terminal di dalam folder `restify_mobile` dan jalankan:
```bash
flutter run
```

---

## Fitur-Fitur Baru Aplikasi Mobile

Berikut adalah beberapa fitur baru yang telah ditambahkan ke dalam aplikasi mobile untuk menyelaraskannya dengan fitur pada aplikasi web:
1. **Asisten AI Rekomendasi (Chatbot)**:
   - Dapat diakses melalui tombol melayang (Floating Action Button) chat di bagian pojok kanan bawah Beranda.
   - Menggunakan model `gemini-1.5-flash` dengan konfigurasi API Key di file `lib/chatbot_page.dart`.
   - Mengambil daftar hotel dari database secara dinamis melalui API `/api/hotels` sebagai konteks rekomendasi.
2. **Checkout Pemesanan**:
   - Menambahkan tombol "Checkout" pada halaman detail pemesanan yang otomatis aktif ketika status pesanan adalah `Checked-in`.
3. **Rating & Ulasan**:
   - Menambahkan tombol "Beri Ulasan" pada halaman detail pemesanan yang otomatis aktif ketika status pesanan adalah `Completed`.
   - Menampilkan dialog / bottom sheet rating (1-5 bintang) dan teks ulasan yang terintegrasi dengan API rating backend.
4. **Lupa Kata Sandi Terintegrasi n8n**:
   - Menyelaraskan alur lupa kata sandi dengan penggunaan kode reset 6 digit (OTP) yang dikirim ke email pengguna via integrasi n8n backend.
   - UI telah disesuaikan agar pengguna menginputkan kode OTP dari email secara manual.

---

## Catatan Penting
- Karena versi gratis dari ngrok digunakan, URL Forwarding akan selalu berubah setiap kali Anda menutup dan membuka ulang ngrok. Oleh karena itu, mohon **selalu mengupdate URL ngrok di kode Flutter setiap kali Anda menjalankan ulang ngrok**.
- Jika API gagal dimuat atau URL salah, aplikasi sudah dilengkapi sistem *fallback* gambar sehingga tidak akan error (layar merah) dan aplikasi tetap berjalan aman menampilkan default gambar.
- Fitur Maps akan otomatis mendeteksi kordinat hotel dan membuka aplikasi Google Maps atau browser di smartphone Anda.
- **Konfigurasi API Key Gemini**: Buka file `lib/chatbot_page.dart` dan ganti `YOUR_GEMINI_API_KEY_HERE` dengan kunci API Gemini Anda yang sebenarnya dari [Google AI Studio](https://aistudio.google.com/) agar Chatbot AI dapat membalas pesan.

