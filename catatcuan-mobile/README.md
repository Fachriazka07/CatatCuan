# CatatCuan Mobile

Project Flutter ini sekarang sudah disiapkan untuk integrasi push notification Firebase Cloud Messaging ke backend CatatCuan.

## Env yang perlu ada di `.env`

Tambahkan selain Supabase:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
MOBILE_BACKEND_BASE_URL=
MOBILE_BACKEND_API_KEY=
```

Contoh `MOBILE_BACKEND_BASE_URL` saat local dev:

```env
MOBILE_BACKEND_BASE_URL=http://10.0.2.2:3000
```

Catatan:

- `10.0.2.2` dipakai jika Flutter jalan di Android emulator dan backend Next.js jalan di laptop yang sama
- kalau pakai HP fisik, ganti dengan IP lokal laptop, misalnya `http://192.168.1.10:3000`

## Setup Firebase Android

Supaya FCM bisa jalan di Android:

1. Tambahkan app Android `com.catatcuan.catatcuan_mobile` di Firebase Console
2. Download `google-services.json`
3. Simpan file itu ke:

```txt
android/app/google-services.json
```

4. Jalankan:

```bash
flutter pub get
flutter run
```

## Yang sudah terhubung

- app startup akan inisialisasi Firebase bila konfigurasi tersedia
- setelah login atau saat sesi lama dipulihkan, app akan ambil FCM token lalu kirim ke backend
- perubahan toggle di halaman notifikasi akan disinkronkan ke backend

## Yang belum selesai

- tampilan UI khusus untuk menerima dan membuka push notification
- flow lupa password berbasis OTP SMS
- konfigurasi iOS
