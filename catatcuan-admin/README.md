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
- `SMS_PROVIDER_MODE`: `log` untuk development, `webhook` untuk provider generic, atau `twilio_verify` untuk OTP SMS sungguhan
- `SMS_PROVIDER_WEBHOOK_URL`: endpoint provider SMS jika mode `webhook`
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_VERIFY_SERVICE_SID`: wajib jika mode `twilio_verify`

Catatan penting:

- Firebase dipakai untuk push notification melalui FCM
- Firebase tidak dipakai di sini sebagai gateway SMS umum
- Untuk SMS reset password, backend sekarang bisa memakai Twilio Verify tanpa mengubah kontrak API mobile

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
- `POST /api/internal/notifications/due-date-reminders`
- `POST /api/internal/notifications/low-stock-alerts`
- `POST /api/internal/notifications/daily-reminders`
- `GET /api/cron/daily-reminders`
- `GET /api/cron/evening-daily-reminder`

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

Contoh trigger reminder hutang jatuh tempo:

```powershell
$headers = @{
  "Content-Type" = "application/json"
  "x-dispatch-secret" = "<NOTIFICATION_DISPATCH_SECRET>"
}

$body = @{
  asOfDate = "2026-03-28"
  lookaheadDays = 1
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:3000/api/internal/notifications/due-date-reminders" `
  -Headers $headers `
  -Body $body
```

Contoh trigger alert stok menipis / habis:

```powershell
$headers = @{
  "Content-Type" = "application/json"
  "x-dispatch-secret" = "<NOTIFICATION_DISPATCH_SECRET>"
}

$body = @{
  asOfDate = "2026-03-28"
  fallbackThreshold = 3
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:3000/api/internal/notifications/low-stock-alerts" `
  -Headers $headers `
  -Body $body
```

Contoh trigger cron harian gabungan secara manual:

```powershell
$headers = @{
  "x-dispatch-secret" = "<NOTIFICATION_DISPATCH_SECRET>"
}

Invoke-RestMethod `
  -Method Get `
  -Uri "http://localhost:3000/api/cron/daily-reminders" `
  -Headers $headers
```

Contoh trigger pengingat catat hari ini secara manual:

```powershell
$headers = @{
  "Content-Type" = "application/json"
  "x-dispatch-secret" = "<NOTIFICATION_DISPATCH_SECRET>"
}

$body = @{
  asOfDate = "2026-03-28"
  timezone = "Asia/Jakarta"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:3000/api/internal/notifications/daily-reminders" `
  -Headers $headers `
  -Body $body
```

Arti proses reminder hutang:

- `lookaheadDays = 1` akan kirim pengingat untuk `H-1`
- tetap kirim untuk yang `hari ini jatuh tempo`
- tetap kirim untuk yang `lewat jatuh tempo`
- hanya memproses `PIUTANG` atau transaksi `kasbon` yang memang punya `tanggal_jatuh_tempo`
- notif dihormati oleh toggle `Pengingat Hutang Jatuh Tempo`
- notif yang sudah `sent` tidak akan dikirim ulang untuk hutang yang sama pada hari yang sama

Arti proses alert stok:

- produk `stok = 0` akan kirim stage `out_of_stock`
- produk `stok > 0` tapi di bawah batas minimum akan kirim stage `low_stock`
- jika `stok_minimum` produk kosong atau `0`, backend akan pakai `fallbackThreshold`
- notif dihormati oleh toggle `Alert Stok Menipis`
- notif yang sudah `sent` tidak akan dikirim ulang untuk produk yang sama, stage yang sama, pada hari yang sama

Arti proses pengingat catat hari ini:

- hanya dikirim jika hari itu belum ada `penjualan`
- dan belum ada `pengeluaran`
- default toggle `Pengingat Catat Hari Ini` tetap `OFF`
- jika user belum pernah menyimpan preferensi notifikasi, backend tetap menganggap `daily_reminder = false`
- notif yang sudah `sent` tidak akan dikirim ulang untuk warung yang sama pada tanggal yang sama

Jadwal otomatis:

- `vercel.json` sudah dijadwalkan `0 0 * * *`
- itu berarti setiap hari jam `00:00 UTC`
- pada zona waktu `WIB / UTC+7`, jadwalnya menjadi setiap hari jam `07:00`
- cron gabungan ini akan memproses:
  - reminder hutang jatuh tempo
  - alert stok menipis / habis
- `vercel.json` juga dijadwalkan `0 12 * * *`
- itu berarti setiap hari jam `12:00 UTC`
- pada zona waktu `WIB / UTC+7`, jadwalnya menjadi setiap hari jam `19:00`
- cron malam ini akan memproses:
  - pengingat `Catat Hari Ini`

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

## Konfigurasi Twilio Verify untuk SMS OTP

Kalau mau pakai SMS OTP sungguhan, isi env berikut:

```env
SMS_PROVIDER_MODE=twilio_verify
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_VERIFY_SERVICE_SID=
```

Perilakunya:

- `POST /api/mobile/auth/request-password-reset` akan memulai verifikasi OTP via Twilio Verify
- `POST /api/mobile/auth/verify-password-reset` akan mengecek kode OTP ke Twilio lalu mengganti password jika statusnya `approved`
- mode `log` dan `webhook` tetap bisa dipakai untuk development atau provider lain
