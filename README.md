# Mobile Restify

Ini adalah aplikasi mobile Flutter untuk Restify (Pemesanan Hotel).

## Persyaratan
- Flutter SDK (versi terbaru)
- Laravel Backend berjalan di lokal (untuk web dan API)
- ngrok (untuk mengekspos API lokal agar bisa diakses dari emulator/perangkat seluler)

## Cara Menjalankan Aplikasi Mobile

Karena aplikasi mobile memerlukan akses ke API dari backend Laravel yang berjalan di lokal Anda, Anda harus menggunakan **ngrok** untuk menghubungkan perangkat mobile ke backend lokal.

### Langkah 1: Jalankan Backend Laravel
Pastikan Anda telah menjalankan proyek Laravel (misal, `restify-webFinal`):
1. Buka terminal di folder backend web Anda.
2. Jalankan perintah:
   ```bash
   php artisan serve
   ```
   (Biasanya berjalan di `http://localhost:8000` atau `http://127.0.0.1:8000`)

### Langkah 2: Jalankan ngrok
Buka terminal baru dan jalankan ngrok untuk mengekspos port tempat backend Laravel berjalan:
```bash
ngrok http 8000
```
Setelah berjalan, ngrok akan memberikan URL Forwarding. Contoh: 
`https://xxxxx.ngrok-free.dev`

### Langkah 3: Update URL ngrok di Aplikasi Flutter
Anda perlu mengganti URL API yang ter-hardcode di kode mobile agar menggunakan URL ngrok Anda yang baru.

1. Copy URL Forwarding dari ngrok.
2. Buka proyek Flutter ini (`mobile_restify`) di VS Code atau editor pilihan Anda.
3. Lakukan **Search and Replace** (Cari dan Ganti) di seluruh file dalam folder `lib/`.
   - Cari: `https://underwear-yeast-aching.ngrok-free.dev` (atau URL ngrok yang lama)
   - Ganti dengan: URL ngrok Anda yang baru (contoh: `https://xxxxx.ngrok-free.dev`)
4. Simpan semua file yang berubah.

### Langkah 4: Jalankan Aplikasi Mobile
Setelah URL API diperbarui, Anda dapat menjalankan aplikasi di emulator Android/iOS atau perangkat fisik.

Jalankan perintah ini di dalam folder `restify_mobile` (atau `mobile_restify` tempat Flutter berada):
```bash
flutter run
```

## Catatan Penting
- Karena kita menggunakan versi gratis dari ngrok, URL Forwarding akan selalu berubah setiap kali Anda merestart ngrok. Oleh karena itu, jangan lupa untuk **selalu mengupdate URL ngrok di kode Flutter setiap kali Anda menjalankan ulang ngrok**.
- Gambar pada aplikasi disesuaikan agar bisa memuat data dari API web, serta diberikan *fallback* gambar agar tampilan tetap aman dan rapi apabila gambar dari API web gagal dimuat.
- Map untuk melihat lokasi hotel akan terbuka langsung menuju aplikasi Google Maps atau browser ke koordinat yang sesuai.
