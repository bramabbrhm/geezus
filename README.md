# GEEZUS — Gamified Outdoor Fitness & Urban Runner

> **Aplikasi Flutter tugas kuliah Pemrograman Aplikasi Mobile (PAM)**  
> Platform: Android (utama) · iOS (didukung) · Web (terbatas — beberapa fitur tidak tersedia)

---

## Deskripsi

**Geezus** adalah aplikasi mobile gamified fitness yang menggabungkan aktivitas dunia nyata (lari, gym, langkah kaki) dengan sistem Boss Battle mingguan dan lencana NFT. Pengguna melacak latihan mereka melalui GPS, sensor akselerometer, dan pencatatan manual via AI Coach untuk mendapatkan "damage" yang digunakan dalam permainan dungeon boss.

---

## Fitur Utama

| Fitur | Status | Keterangan |
|---|---|---|
| Login & Register | ✅ Berjalan | Supabase Auth + fallback lokal (hashed password) |
| Sesi otomatis | ✅ Berjalan | Cek session saat startup, redirect ke Login/Home |
| Logout + konfirmasi | ✅ Berjalan | Navigasi dibersihkan setelah logout |
| GPS Live Tracking | ✅ Berjalan | Peta OpenStreetMap, polyline, timer, simpan ke SQLite |
| Step Counter | ✅ Berjalan | Sensor akselerometer, persist harian ke SQLite |
| Notifikasi Hidrasi | ✅ Berjalan | Jadwal periodik, ON/OFF, interval, tes langsung |
| Notifikasi Lari | ✅ Berjalan | Jadwal harian, ON/OFF, pilih waktu, tes langsung |
| SQLite Persistence | ✅ Berjalan | Tabel: run_history, gym_logs, step_counter |
| AI Coach (Gemini) | ✅ Berjalan | Butuh GEMINI_API_KEY; parsing gym lokal tanpa API |
| Boss Battle | ✅ Berjalan | HP boss, serangan, animasi, data dari GymStore nyata |
| NFT Badges | ⚠️ Simulasi | Hash transaksi palsu, berlabel `[SIMULASI]` |
| Cari Rute | ✅ Berjalan | Ambil dari tabel `routes` Supabase |
| Modul Konversi | ✅ Berjalan | IDR→USD/EUR/SGD + zona waktu real-time |
| Saran & Kesan PAM | ✅ Berjalan | Simpan ke SharedPreferences |
| Biometrik Login | ✅ Berjalan | Butuh perangkat yang mendukung fingerprint |
| Background Tracking | ❌ Tidak ada | GPS hanya aktif saat aplikasi di foreground |
| NFT Blockchain nyata | ❌ Tidak ada | Butuh wallet, smart contract, dan integrasi web3dart |

---

## Teknologi yang Digunakan

- **Flutter 3.x** (Dart ≥ 3.12.2)
- **Supabase Flutter** — autentikasi dan penyimpanan cloud
- **flutter_local_notifications** v22 — notifikasi lokal terjadwal
- **geolocator** — GPS/lokasi
- **flutter_map** + **latlong2** — peta OpenStreetMap
- **sensors_plus** — akselerometer & giroskop
- **google_generative_ai** — Gemini AI Coach
- **sqflite** — SQLite lokal
- **flutter_secure_storage** — penyimpanan session terenkripsi
- **shared_preferences** — preferensi pengguna
- **local_auth** — biometrik
- **flutter_dotenv** — konfigurasi environment
- **crypto** — hash password lokal
- **intl** — format angka dan tanggal

---

## Struktur Folder

```
lib/
├── core/
│   ├── constants/        # Warna tema (app_colors.dart)
│   ├── services/         # GymStore — state terpusat latihan & lari
│   ├── storage/          # SqliteHelper, SecureStorageHelper
│   └── utils/            # NotificationService
├── features/
│   ├── ai_coach/         # Gemini AI Coach (controller, model, view)
│   ├── auth/             # Login, Register, Profile, Konversi, Saran/Kesan
│   ├── boss_battle/      # Layar Boss Battle
│   ├── pam_feedback/     # Re-export SaranKesanScreen
│   ├── tracking/         # LiveRun, StepCounter, SearchRoutes, NotificationSettings
│   └── web3_nft/         # Badge controller, model, view (simulasi)
├── shared/
│   └── root_navigation.dart  # Bottom navigation
└── main.dart             # Entry point, session check, Supabase init
```

---

## Instalasi dan Menjalankan Aplikasi

### 1. Clone/Ekstrak Project

```bash
# Pastikan Flutter SDK sudah terinstall
flutter --version
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Konfigurasi Environment

Salin file contoh dan isi kredensial:

```bash
# File .env tidak masuk ke git — buat secara manual
# (atau isi langsung di android/ios secara local)
```

Buat file `.env` di root project (sejajar dengan `pubspec.yaml`):

```dotenv
GEMINI_API_KEY=your_actual_gemini_api_key_here
SUPABASE_URL=https://yourproject.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

> **Catatan:** Jika `.env` tidak ada, aplikasi akan menggunakan nilai fallback yang tertanam di kode (`main.dart`).  
> File `.env` di-gitignore — JANGAN commit ke repository.

### 4. Jalankan Aplikasi

```bash
# Android (perangkat fisik direkomendasikan untuk GPS + sensor)
flutter run

# Android dengan API key Gemini disuntik via --dart-define
flutter run --dart-define=GEMINI_API_KEY=your_key_here

# Web (terbatas: tanpa notifikasi, GPS, sensor)
flutter run -d chrome
```

---

## Konfigurasi Gemini API

1. Kunjungi [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Buat API Key baru
3. Tambahkan ke `.env`:
   ```
   GEMINI_API_KEY=AIza...
   ```
4. Restart aplikasi

Tanpa API key, fitur tanya-jawab AI tidak aktif. Pencatatan gym lokal tetap bekerja tanpa API key.

---

## Konfigurasi Supabase

### Setup Project

1. Buat project baru di [https://supabase.com](https://supabase.com)
2. Ambil **Project URL** dan **Anon Key** dari Settings → API
3. Tambahkan ke `.env`

### Tabel yang Diperlukan

Jalankan SQL berikut di Supabase SQL Editor:

```sql
-- Tabel profil pengguna
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT,
  username TEXT,
  level INTEGER DEFAULT 1,
  total_xp INTEGER DEFAULT 0,
  boss_damage_total INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabel rute lari
CREATE TABLE IF NOT EXISTS routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  activity_type TEXT DEFAULT 'running',
  distance_km REAL NOT NULL,
  difficulty TEXT DEFAULT 'Easy',
  description TEXT,
  start_lat REAL,
  start_lng REAL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Contoh data rute
INSERT INTO routes (name, distance_km, difficulty, start_lat, start_lng, description)
VALUES
  ('Rute Kampus UGM', 5.2, 'Easy', -7.7700, 110.3775, 'Rute lari ringan di area kampus'),
  ('Jalur Merapi Trail', 10.0, 'Hard', -7.6414, 110.4458, 'Trek gunung dengan elevasi tinggi'),
  ('Jalan Malioboro Loop', 7.5, 'Medium', -7.7956, 110.3695, 'Rute tengah kota dengan pemandangan');

-- Row Level Security (RLS) — izinkan read publik untuk routes
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read routes" ON routes FOR SELECT USING (true);

-- RLS untuk profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Service can insert profile" ON profiles FOR INSERT WITH CHECK (true);
```

---

## Konfigurasi Notifikasi Android

Pastikan `AndroidManifest.xml` sudah memiliki permission berikut (sudah ditambahkan):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

Untuk Android 13+, aplikasi akan meminta izin notifikasi di runtime saat pengguna pertama kali mengaktifkan pengingat.

---

## Struktur Database SQLite Lokal

| Tabel | Kolom | Deskripsi |
|---|---|---|
| `run_history` | id, distance_km, duration_seconds, estimated_calories, boss_damage, date | Riwayat setiap sesi lari |
| `gym_logs` | id, exercise_name, weight_kg, sets, reps, volume_kg, date | Log latihan gym dari AI Coach |
| `step_counter` | id, date (UNIQUE), step_count, estimated_km, estimated_calories | Hitungan langkah harian |
| `workouts` | id, distance, durationSeconds, calories, date | Tabel lama (backward compat) |

---

## Cara Menjalankan Test

```bash
# Unit tests (lokal, tanpa internet, tanpa Flutter widget binding)
flutter test test/widget_test.dart
flutter test test/ai_coach_test.dart

# Semua test
flutter test

# Test integrasi AI Coach (butuh API key nyata)
# Edit test/ai_coach_test.dart: hapus 'skip:' pada test #6
flutter test test/ai_coach_test.dart
```

---

## Fitur yang Benar-Benar Berjalan

- ✅ Login/Register via Supabase + fallback lokal
- ✅ Session check saat startup (redirect Login atau Home)
- ✅ Logout + konfirmasi + clear navigasi
- ✅ GPS tracking dengan peta OpenStreetMap, polyline, timer
- ✅ Penyimpanan riwayat lari ke SQLite
- ✅ Step counter dengan sensor akselerometer + persist harian
- ✅ Notifikasi pengingat hidrasi (periodic hourly)
- ✅ Notifikasi pengingat lari (periodic daily)
- ✅ ON/OFF switch + pilih interval/waktu + tes langsung
- ✅ AI Coach: parsing gym log lokal (tanpa internet)
- ✅ AI Coach: tanya-jawab via Gemini (butuh API key)
- ✅ Boss Battle: damage dari gym + lari nyata (dari GymStore/SQLite)
- ✅ Navigasi ke semua screen dari Profile
- ✅ Modul konversi mata uang + zona waktu real-time
- ✅ Saran & Kesan PAM tersimpan di SharedPreferences

## Fitur yang Masih Simulasi

- ⚠️ **NFT Minting**: Hash transaksi dihasilkan secara acak dan berlabel `[SIMULASI]`. Tidak ada transaksi blockchain nyata.
- ⚠️ **Jadwal notifikasi tepat waktu**: Menggunakan `RepeatInterval.hourly/daily` yang bersifat inexact di Android (OS bisa menunda demi efisiensi baterai). Untuk jadwal tepat waktu perlu WorkManager.
- ⚠️ **Background GPS tracking**: Tracking berhenti saat aplikasi ditutup. Background tracking membutuhkan `background_location` atau foreground service tambahan.
- ⚠️ **Badge Boss Slayer**: Belum ada koneksi otomatis dari event "boss dikalahkan" ke unlock badge (harus unlock manual via `toggleUnlock`).

---

## Catatan Keamanan

- Jangan simpan API key di source code atau commit ke repository
- File `.env` sudah di-gitignore
- Supabase Anon Key bisa dibaca client — itu memang desain Supabase (key ini bukan secret)
- Password hash lokal menggunakan SHA-256 — hanya sebagai fallback offline
- Jangan gunakan fallback login lokal untuk aplikasi produksi

---

*Dibuat untuk tugas kuliah Pemrograman Aplikasi Mobile (PAM)*
