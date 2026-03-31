# CatatCuan Admin

Panel admin Next.js ini juga sekarang menjadi backend tipis untuk kebutuhan mobile yang belum bisa diselesaikan langsung dari Supabase RPC, terutama:

- registrasi token Firebase Cloud Messaging
- sinkron preferensi notifikasi dari mobile
- reset password berbasis OTP SMS
- dispatch push notification dari backend

## Menjalankan project

1. Salin `.env.example` menjadi `.env.local`
2. Isi `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, dan `DATABASE_URL`
3. Jalankan install dependency
4. Jalankan server:

```bash
npm run dev
```

## Env tambahan untuk mobile backend

Field baru yang wajib diperhatikan:

- `MOBILE_BACKEND_API_KEY`: dipakai mobile app saat memanggil route backend
- `NOTIFICATION_DISPATCH_SECRET`: dipakai route internal untuk trigger push notification
- `FIREBASE_SERVICE_ACCOUNT_JSON`: credential Firebase Admin untuk kirim FCM
- `SMS_PROVIDER_MODE`: `log` untuk development, `webhook` untuk provider SMS nyata
- `SMS_PROVIDER_WEBHOOK_URL`: endpoint provider SMS jika mode `webhook`

Catatan penting:

- Firebase dipakai untuk push notification melalui FCM
- Firebase tidak dipakai di sini sebagai gateway SMS umum
- Untuk SMS reset password, backend memakai abstraction provider supaya bisa disambungkan ke vendor lokal atau gateway lain tanpa ubah flow aplikasi

## Migration yang perlu dijalankan

Jalankan file berikut di Supabase SQL Editor:

- `migrations/hash_mobile_user_passwords.sql`
- `migrations/change_mobile_user_password.sql`
- `migrations/add_mobile_notifications_and_password_reset.sql`

## Endpoint backend baru

Semua route mobile memakai header:

```txt
x-mobile-api-key: <MOBILE_BACKEND_API_KEY>
```

Route yang tersedia:

- `POST /api/mobile/device-token`
- `DELETE /api/mobile/device-token`
- `POST /api/mobile/notification-preferences`
- `POST /api/mobile/auth/request-password-reset`
- `POST /api/mobile/auth/verify-password-reset`

Route internal untuk trigger push:

```txt
x-dispatch-secret: <NOTIFICATION_DISPATCH_SECRET>
```

- `POST /api/internal/notifications/push`

Contoh test push notification dari PowerShell:

```powershell
$headers = @{
  "Content-Type" = "application/json"
  "x-dispatch-secret" = "<NOTIFICATION_DISPATCH_SECRET>"
}

$body = @{
  userId = "<USER_ID_MOBILE>"
  title = "Tes Notifikasi"
  body = "Push notification CatatCuan berhasil terkirim."
  notificationType = "manual_test"
  data = @{
    screen = "home"
  }
} | ConvertTo-Json -Depth 4

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:3000/api/internal/notifications/push" `
  -Headers $headers `
  -Body $body
```

Untuk memastikan device token sudah masuk, cek tabel:

```sql
select * from public."MOBILE_DEVICE_TOKENS" order by updated_at desc;
```

## Langkah lanjutan di mobile

Backend ini belum otomatis aktif tanpa integrasi mobile. Supaya benar-benar jalan, mobile app masih perlu:

1. Menambahkan Firebase Messaging SDK
2. Mengambil FCM token setelah login
3. Mengirim token ke `POST /api/mobile/device-token`
4. Mengirim toggle notifikasi settings ke `POST /api/mobile/notification-preferences`
5. Mengganti flow `Lupa Password` agar request OTP dan verifikasi memakai route backend baru


$headers = @{
  "Content-Type" = "application/json"
  "x-dispatch-secret" = "<ISI_NOTIFICATION_DISPATCH_SECRET_DARI_.env.local>"
}

$body = @{
  userId = "711a7019-b8e1-40f1-a4c9-0f1c8087dc08"
  title = "Tes Notifikasi"
  body = "Kalau ini muncul berarti push notification jalan."
  notificationType = "manual_test"
  data = @{
    screen = "home"
  }
} | ConvertTo-Json -Depth 4

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:3000/api/internal/notifications/push" `
  -Headers $headers `
  -Body $body

